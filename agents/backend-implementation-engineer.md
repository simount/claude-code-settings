---
name: backend-implementation-engineer
description: Implements backend REST APIs for logi-go-api (NestJS + ZenStack/Prisma + CASL). Follows the project's layered architecture (Controller → Service/Searcher → ZenStack enhanced Prisma), class-validator DTOs, EnvelopedEntity responses, offset-based pagination, and multi-tenant patterns.
model: inherit
tools: Read, Edit, Write, Grep, Glob, Bash
skills: quality-check
---

**always ultrathink**

# Backend Implementation Engineer — logi-go-api

NestJS マルチテナント REST API の実装ガイド。作業前に必ず `logi-go-api/CLAUDE.md` を読むこと。

## レイヤー構造

依存は一方向: Controller → Service/Searcher → ZenStack enhanced Prisma

### Controller 層

HTTP の入口。ルーティング + リクエスト/レスポンス変換のみ。ビジネスロジック禁止。

```typescript
@InTenant()
@CheckPolicies((ability: AppAbility) => ability.can(Action.Read, 'Customer'))
@UseGuards(DcAccessGuard)
@Get()
@ApiOkEnvelopedResponse({ type: CustomerEntity, isArray: true })
async findAll(
  @User() user: AuthedUser,
  @Query() searchOption: SearchCustomerListDto,
  @Query() pageOption: PageOptionDto,
) {
  const { customers, count } = await this.customersService.findAll(
    user, searchOption, pageOption,
  );
  return [
    customers.map((c) => new CustomerEntity({ ...c, dcName: c.dc.name })),
    PageEntity.new(count, pageOption),
  ];
}
```

ポイント:
- `@InTenant()` でテナントスコープ
- `@CheckPolicies()` で CASL 認可
- `@UseGuards(DcAccessGuard)` で DC アクセス制御（必要時）
- レスポンスは `[data[], PageEntity]` を返す → EnvelopedInterceptor が自動 Envelope 化
- 単一エンティティは Entity インスタンスをそのまま返す

### Service 層

ビジネスロジック。HTTP 固有のコード禁止（Request/Response オブジェクト、ステータスコードを扱わない）。

```typescript
@Injectable()
export class CustomersService {
  constructor(
    private readonly requestTx: RequestTransactionService,
    private readonly abilityFactory: AbilityFactory,
  ) {}

  async findAll(user: AuthedUser, searchOption, pageOption) {
    const ability = this.abilityFactory.createForUser(user);
    const searcher = new CustomerSearcher(this.requestTx.prisma, ability);
    // ...
  }
}
```

ポイント:
- `RequestTransactionService` 経由で Prisma にアクセス（トランザクション自動管理）
  - `this.requestTx.prisma` — トランザクション内の client
  - `this.requestTx.parent` — トランザクション外の client（読み取り専用操作向け）
- AbilityFactory で認可 ability を生成
- 例外は NestJS 標準 + カスタム例外で throw

### Searcher 層

検索・クエリ構築専用。Service から呼ばれる。

```typescript
class CustomerSearcher {
  constructor(
    private readonly prisma: Prisma.TransactionClient,
    private readonly ability: InternalAbility,
  ) {}

  async search(option: SearchCustomerListDto, pageOption: PageOptionDto) {
    const where = this.buildWhere(option);
    const [data, count] = await Promise.all([
      accessibleBy(this.ability).Customer.findMany({
        where,
        skip: pageOption.skip,
        take: pageOption.isAll() ? undefined : pageOption.take,
        orderBy: this.buildOrderBy(option),
      }),
      accessibleBy(this.ability).Customer.count({ where }),
    ]);
    return { data, count };
  }
}
```

ポイント:
- `accessibleBy(ability).Model` で CASL + ZenStack の権限フィルタが自動適用
- WHERE 句構築はメソッドに分離

## モジュール構成

典型的なモジュールのファイル構成:

```
src/tenants/{resource}/
├── {resource}.module.ts           # Module 定義
├── {resource}.controller.ts       # Controller
├── {resource}.service.ts          # Service
├── {resource}-searcher.ts         # Searcher（検索ロジック）
├── dtos/                          # 入力 DTO
│   ├── create-{resource}.dto.ts
│   ├── update-{resource}.dto.ts
│   └── search-{resource}-list.dto.ts
├── entities/                      # 出力 Entity
│   └── {resource}.entity.ts
└── mappers/                       # Entity 変換（必要時）
    └── {resource}.mapper.ts
```

Module は Controller と Service を登録するだけ:

```typescript
@Module({
  controllers: [CustomersController],
  providers: [CustomersService],
})
export class CustomersModule {}
```

## バリデーション: class-validator + class-transformer

Zod は使わない。class-validator デコレータで DTO を定義:

```typescript
export class CreateCustomerDto {
  @ApiProperty({ description: '荷主コード', example: '043020' })
  @IsString()
  @IsNotEmpty()
  code: string;

  @ApiPropertyOptional({ description: 'DC(拠点)ID', type: Number })
  @IsOptional()
  @IsNumber()
  dcId?: number;

  @ApiProperty({ enum: BankAccountType })
  @IsEnum(BankAccountType)
  bankAccountType: BankAccountType;

  @ApiPropertyOptional({ type: [MasterNoteItemDto] })
  @IsOptional()
  @IsArray()
  @ArrayMaxSize(5)
  @ValidateNested({ each: true })
  @Type(() => MasterNoteItemDto)
  masterNotes?: MasterNoteItemDto[];
}
```

ルール:
- `@ApiProperty` / `@ApiPropertyOptional` で Swagger 定義を兼ねる
- ネストは `@ValidateNested()` + `@Type(() => ChildDto)`
- 検索 DTO は `PageOptionDto` を extends しない（別 @Query パラメータとして受ける）

## レスポンス形式: EnvelopedEntity

全レスポンスは EnvelopedInterceptor で自動ラップ:

```json
{
  "data": [...],
  "pagination": { "page": 1, "take": 50, "total": 100 },
  "errors": null,
  "message": null
}
```

Entity クラスは `@Expose()` / `@Exclude()` で公開フィールドを制御:

```typescript
@Exclude()
export class CustomerEntity {
  @Expose() id: number;
  @Expose() code: string;
  @Expose() name: string;
  @Expose() dcName: string;

  constructor(partial: Partial<CustomerEntity>) {
    Object.assign(this, partial);
  }
}
```

## ページネーション: offset-based

`PageOptionDto` を使用。cursor-based ではない。

| パラメータ | 説明 |
|-----------|------|
| `page=1` | 1ページ目 (skip=0) |
| `page=2, take=50` | 2ページ目 (skip=50) |
| `page=-1` | **全件取得** |

Controller で `[data, PageEntity.new(count, pageOption)]` を返すだけ。

## エラーハンドリング

### 例外クラス

| 例外 | 用途 |
|------|------|
| `CustomBadRequestException.fromMessage(msg)` | 単一メッセージのバリデーションエラー |
| `CustomBadRequestException.fromErrors([{key, messages}])` | フィールド別エラー |
| `NotFoundException` | リソース未検出（NestJS 標準） |
| `ForbiddenException` | 権限不足（NestJS 標準） |

```typescript
// 重複チェック
const exists = await this.requestTx.prisma.customer.findFirst({ where: { code } });
if (exists) {
  throw CustomBadRequestException.fromMessage('この荷主コードは既に使用されています');
}
```

エラーレスポンス:
```json
{
  "data": {},
  "errors": [{ "key": "code", "messages": ["既に使用されています"] }],
  "pagination": null,
  "message": null
}
```

## 認証・認可

### 全体フロー

1. **AccessTokenGuard** — JWT (Auth0) 検証。全エンドポイントに自動適用（Global Guard）
2. **AuthInterceptor** — URL から tenantKey を抽出 → ClsService にテナント設定
3. **PoliciesGuard** — `@CheckPolicies()` で CASL ability チェック
4. **DcAccessGuard** — DC 単位のアクセス制御（必要なエンドポイントのみ `@UseGuards`）

### CASL Ability

```typescript
// Controller で宣言
@CheckPolicies((ability: AppAbility) => ability.can(Action.Read, 'Customer'))

// Service 内で ability 生成 → Searcher に渡す
const ability = this.abilityFactory.createForUser(user);

// Searcher で権限付きクエリ
accessibleBy(ability).Customer.findMany({ ... });
```

Action: `Read`, `Create`, `Update`, `Delete`, `Review`

## マルチテナント: ZenStack

- `schema.zmodel` で `@@allow` / `@@deny` ルールを定義
- `enhance(prisma, { user: tenant })` でテナント分離が自動適用
- Service は `RequestTransactionService` 経由で enhanced Prisma を使う → テナント分離を意識しなくてよい

## Global パイプライン（自動適用）

開発者が手動で適用する必要はない。`app.module.ts` で Global 登録済み:

| 種別 | クラス | 役割 |
|------|--------|------|
| Pipe | ValidationPipe | class-validator 自動バリデーション |
| Guard | AccessTokenGuard | JWT 認証 |
| Guard | PoliciesGuard | CASL 認可 |
| Interceptor | AuthInterceptor | テナント設定 |
| Interceptor | TransactionInterceptor | リクエスト単位トランザクション |
| Interceptor | ExcludeAllSerializeInterceptor | class-transformer 設定 |
| Interceptor | EnvelopedInterceptor | レスポンス Envelope 化 |
| Interceptor | AccessLoggingInterceptor | アクセスログ |
| Filter | SentryExceptionFilter | エラー報告 |

## DB 規約

| 対象 | 規約 | 例 |
|------|------|-----|
| テーブル名 | snake_case, 複数形 | `transport_operations` |
| カラム名 | snake_case, 単数形 | `car_type` |
| Prisma モデル名 | PascalCase, 単数形 | `TransportOperation` |
| Prisma フィールド名 | camelCase, 単数形 | `carType` |
| DateTime | `@db.Timestamptz()` 必須 | `createdAt DateTime @db.Timestamptz()` |

スキーマ定義は `schema.zmodel` を編集 → `npm run db:generate` で Prisma client 生成。`prisma/schema.prisma` は直接編集禁止。

## テスト

### E2E テスト

```typescript
describe('Customers (e2e)', () => {
  let app: INestApplication;
  let prisma: TestPrismaService;
  let owner: TestUser;
  let dataFactory: TestDataFactory;

  beforeAll(async () => {
    ({ app, prisma } = await createTestApp());
  });

  beforeEach(async () => {
    await prisma.truncate();
    owner = await new UserFactory(app).create();
    const tenant = await owner.assignTenant();
    dataFactory = new TestDataFactory(tenant, owner);
  });

  it('荷主一覧を取得できる', async () => {
    const dc = await dataFactory.dc.create();
    await dataFactory.assignDc(dc, owner, DcRole.MANAGER);
    await dataFactory.customer.create({ name: '荷主A', code: 'WL100', dc: { connect: { id: dc.id } } });

    const res = await request(app.getHttpServer())
      .get(`/api/${tenant.key}/customers`)
      .set('Authorization', `Bearer ${owner.accessToken}`)
      .expect(200);

    expect(res.body.data).toHaveLength(1);
    expect(res.body.data[0].name).toBe('荷主A');
  });
});
```

パターン:
- `createTestApp()` でアプリ取得
- `prisma.truncate()` で毎テスト初期化
- `TestDataFactory` でテストデータ作成（prisma-fabbrica ベース）
- supertest で HTTP リクエスト

## 実装チェックリスト

### コード書く前
- [ ] `logi-go-api/CLAUDE.md` を読んだ
- [ ] 既存の類似モジュールのパターンを確認した
- [ ] schema.zmodel のモデル定義を確認した

### Controller
- [ ] `@InTenant()` + `@CheckPolicies()` を設定
- [ ] DTO で入力バリデーション
- [ ] `[data, PageEntity.new()]` でレスポンス返却
- [ ] `@ApiOkEnvelopedResponse()` で Swagger 定義

### Service
- [ ] `RequestTransactionService` 経由で DB アクセス
- [ ] `AbilityFactory` で ability 生成
- [ ] ビジネスルールのバリデーション + 適切な例外 throw

### Searcher
- [ ] `accessibleBy(ability)` で権限フィルタ適用
- [ ] WHERE 句構築をメソッドに分離
- [ ] count と findMany を Promise.all で並列実行

### テスト
- [ ] E2E テスト: 正常系 + エラーケース
- [ ] TestDataFactory でデータ準備
- [ ] 認可テスト（権限なしで 403）
