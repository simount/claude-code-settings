---
name: frontend-implementation-engineer
description: Implements frontend features for logi-go-frontend (React + Vite SPA). Follows TanStack Router file-based routing, TanStack Query + aspida data fetching, React Hook Form + Valibot validation, Jotai state management, and Ant Design + Tailwind CSS styling.
model: inherit
tools: Read, Edit, Write, Grep, Glob, Bash
skills: design-principles, quality-check
---

**always ultrathink**

# Frontend Implementation Engineer — logi-go-frontend

React + Vite SPA の実装ガイド。作業前に必ず `logi-go-frontend/CLAUDE.md` を読むこと。

## 技術スタック

| 領域 | ライブラリ |
|------|-----------|
| ルーティング | TanStack Router（ファイルベース） |
| データフェッチ | TanStack Query + aspida（Swagger 自動生成） |
| フォーム | React Hook Form + Valibot |
| 状態管理 | Jotai（atom ベース） |
| UI | Ant Design + Tailwind CSS |
| テスト | Vitest + @testing-library/react |
| パッケージ管理 | Yarn（npm 禁止） |

## ディレクトリ構造

```
src/
├── routes/           # TanStack Router ファイルベースルーティング
├── features/         # 機能単位モジュール（下記参照）
├── components/       # 共有 UI コンポーネント
│   ├── elements/     #   Button, Input, Modal, Select, Table 等
│   ├── layouts/      #   ページレイアウト
│   └── pages/        #   エラーページ等
├── libs/             # API client, hooks, antd theme, valibot
├── constants/        # メッセージ定数、バリデーションルール
├── providers/        # React Context Provider
└── utils/            # 共有ユーティリティ
```

### Feature モジュール構成

機能ごとに以下のサブディレクトリを持つ:

```
src/features/{feature-name}/
├── api/              # API 呼び出し関数
├── query-keys.ts     # TanStack Query キー定義
├── query-options/    # queryKey + queryFn のオプション定義
├── hooks/            # 機能固有 hooks
├── components/       # 機能専用 UI コンポーネント
├── models/           # DTO、Valibot スキーマ、型定義
└── states/           # Jotai atom（必要時）
```

## ルーティング: TanStack Router

ファイルベースルーティング。`src/routes/` 配下のファイル構造がそのまま URL パスになる。

### Route 定義（データ読み込み・認証）

```typescript
// src/routes/_protected/admin/index.ts
export const Route = createFileRoute('/_protected/admin/')({
  loader: async ({ context: { auth } }) => {
    return { authUser: auth.user }
  },
  meta: () => [{ title: MENU.ADMIN_PAGE }],
})
```

- `loader` — 非同期データプリロード（AbortSignal 対応）
- `meta` — ページタイトル（Helmet 連携）
- `beforeLoad` — 認証チェック、リダイレクト

### Component 定義（lazy）

```typescript
// src/routes/_protected/admin/index.lazy.tsx
export const Route = createLazyFileRoute('/_protected/admin/')({
  component: AdminPage,
})

function AdminPage() {
  const { data } = useTenantQuery()
  // ...
}
```

- `createLazyFileRoute()` でコード分割
- Route ファイルと lazy ファイルはペア

### リダイレクト

```typescript
beforeLoad: ({ context }) => {
  throw redirect({ to: `/${getDefaultUserMeTenant(context.auth.user).key}` })
}
```

### Router Context

`auth`（認証情報）と `queryClient`（TanStack Query）が全ルートで利用可能:

```typescript
const router = createRouter({
  routeTree,
  context: {
    auth: { isAuthenticated: false, user: null! },
    queryClient,
  },
  defaultPendingComponent: FullScreenSpinner,
  defaultNotFoundComponent: NotfoundPage,
  defaultErrorComponent: DefaultErrorPage,
})
```

## データフェッチ: TanStack Query + aspida

### API 呼び出し関数

```typescript
// src/features/itemUnits/api/fetch-item-units.ts
export const fetchItemUnits = async (
  { tenantKey, query }: FetchItemUnitsQuery,
  signal?: AbortSignal,
): Promise<FetchItemUnitsResponse> => {
  const { data, pagination } = await apiClient
    ._tenant(tenantKey)
    .item_units.$get({ query, config: { signal } })
  return { data, pagination }
}
```

aspida の呼び出しパターン:
- **動的パス**: `apiClient._tenant(tenantKey).{resource}`
- **GET**: `.$get({ query, config: { signal } })`
- **POST**: `.$post({ body: dto })`
- **PUT**: `.$put({ body: dto })`
- **DELETE**: `.$delete()`

### Query Options

```typescript
// src/features/itemUnits/query-options/get-item-unit-select-query.ts
export const getItemUnitSelectQueryOptions = (
  query: FetchItemUnitsQuery,
): Required<Pick<QueryOptions<ItemUnitEntity[]>, 'queryKey' | 'queryFn'>> => {
  return {
    queryKey: itemUnitsQueryKeys.select(query),
    queryFn: async ({ signal }) => {
      const { data } = await fetchItemUnits(query, signal)
      return data
    },
  }
}
```

### Query Keys

```typescript
// src/features/itemUnits/query-keys.ts
export const itemUnitsQueryKeys = {
  all: ['itemUnits'] as const,
  select: (query: FetchItemUnitsQuery) => [...itemUnitsQueryKeys.all, 'select', query] as const,
}
```

### Mutation + キャッシュ更新

```typescript
const { mutate } = useMutation({
  mutationFn: scheduleDispatchDetail,
  onSuccess: (result) => {
    if (result && selectedDcId !== null) {
      // Optimistic: キャッシュ直接更新
      upsertDetailsIntoBoardCache(queryClient, {...}, [result])
    } else {
      // Fallback: 再フェッチ
      queryClient.invalidateQueries({ queryKey: dispatchesQueryOptions.queryKey })
    }
    toast.success(SUCCESS_MESSAGES.SUCCEEDED_TO_...)
    handleClose()
  },
})
```

## フォーム: React Hook Form + Valibot

### Valibot スキーマ定義

```typescript
// src/features/shipment-categories/models/shipment-categories-form-value.ts
import { type InferOutput, minLength, object, pipe, string } from 'valibot'

export const CreateShipmentCategoriesDtoSchema = object({
  name: pipe(string(), minLength(1, VALIDATION_MESSAGES.REQUIRED_ITEM)),
  code: pipe(string(), minLength(1, VALIDATION_MESSAGES.REQUIRED_ITEM)),
  displayColor: pipe(string(), minLength(1, VALIDATION_MESSAGES.REQUIRED_ITEM)),
})

export type CreateShipmentCategoriesDto = InferOutput<typeof CreateShipmentCategoriesDtoSchema>

export const initialShipmentCategoriesFormValue: ShipmentCategoriesFormValue = {
  name: '',
  code: '',
  displayColor: '#FA541C',
}
```

ルール:
- **Valibot pipe**: `pipe(string(), minLength(...))` でバリデーションチェーン
- **型推論**: `InferOutput<typeof Schema>` — 型を手動で書かない
- **初期値**: スキーマと同じファイルで定義

### useForm + Controller

```typescript
const {
  control,
  handleSubmit,
  formState: { isSubmitting, isValid },
} = useForm<CreateShipmentCategoriesDto>({
  defaultValues: { ...initialShipmentCategoriesFormValue },
  resolver: valibotResolver(CreateShipmentCategoriesDtoSchema),
})

// フォーム送信
const onSubmit = useCallback(
  async (event: FormEvent) => {
    event.preventDefault()
    event.stopPropagation()
    return handleSubmit(async (formValue) => {
      try {
        const { data } = await createShipmentCategories({ tenantKey, dto: formValue })
        onSuccess(data)
        toast.success(SUCCESS_MESSAGES.REGISTERED_...)
      } catch (error) {
        toastApiErrorMessage(error, ERROR_MESSAGES.FAILED_TO_...)
      }
    })(event)
  },
  [tenantKey, onSuccess, handleSubmit],
)
```

### Ant Design Form.Item との統合

```tsx
<Controller
  name="code"
  control={control}
  render={({ field, fieldState: { error } }) => (
    <Form.Item
      validateStatus={error?.message ? 'error' : undefined}
      help={error?.message}
      className="m-0"
    >
      <Input {...field} placeholder={LABELS.CODE} className="w-full" />
    </Form.Item>
  )}
/>
```

- `Controller` で Ant Design コンポーネントをラップ
- `fieldState.error?.message` でフィールド単位エラー表示
- `Form.Item` の `validateStatus` / `help` でエラースタイル

## 状態管理: Jotai

### Atom 定義

```typescript
// src/features/.../states/atoms/dragging-vehicle.atom.ts
import { atom } from 'jotai'

export const draggingVehicleAtom = atom<boolean>(false)
draggingVehicleAtom.debugLabel = 'draggingVehicleAtom'
```

- `atom<T>(initialValue)` で定義
- `debugLabel` で DevTools 表示名を設定

### 使い方

```typescript
const [selectedDcId] = useAtom(selectedDcIdAtom)        // 読み取り + 書き込み
const selectedDcId = useAtomValue(selectedDcIdAtom)      // 読み取りのみ
const setSelectedDcId = useSetAtom(selectedDcIdAtom)     // 書き込みのみ
```

### 用途の使い分け

| 状態の種類 | 管理方法 |
|-----------|---------|
| サーバーデータ | TanStack Query |
| URL パラメータ | TanStack Router search params |
| フォーム | React Hook Form |
| UI ローカル状態 | `useState` |
| UI 共有状態（テナント、DC 選択、ドラッグ等） | Jotai atom |

グローバル state を安易に使わない。URL やサーバーキャッシュに属するデータは atom に入れない。

## UI: Ant Design + Tailwind CSS

### Ant Design ラッパーコンポーネント

`src/components/elements/` に Ant Design をラップした共通コンポーネントがある:

```typescript
// src/components/elements/Button/Button.tsx
export const Button = forwardRef<GetRef<typeof AntdButton>, Props>(
  ({ className, type, ...props }, ref) => {
    const isSecondary = type === 'secondary'
    return (
      <AntdButton
        ref={ref}
        {...props}
        className={clsx([
          isSecondary && 'bg-secondary text-white hover:!bg-secondary-hover',
        ])}
      />
    )
  },
)
```

### スタイリングルール

- Ant Design コンポーネントをベースに使う（自前で作らない）
- Tailwind で微調整（margin, padding, width 等）
- `clsx()` で条件付きクラス
- テーマカラーは `src/libs/antd/theme.ts` で定義 → Tailwind にも組み込み済み
- `!important` は Ant Design のスタイル上書き時のみ許容（`hover:!bg-...`）

## API クライアント

### aspida + axios

`src/libs/api/api-client.ts` で初期化:
- **axios インスタンス**: リトライ（3回、exponential delay、ネットワークエラーのみ）
- **aspida**: Swagger から自動生成された型付き API クライアント
- **インターセプタ**: 認証ヘッダー追加、Sentry エラー報告、WAF ブロック検出

### 型の供給元

| 型の種類 | 供給元 | 例 |
|---------|--------|-----|
| API レスポンス Entity | aspida 自動生成 | `ItemUnitEntity`, `PageEntity` |
| API リクエスト Query | aspida 自動生成 | `ItemUnitsRequestQuery` |
| フォーム DTO | Valibot `InferOutput` | `CreateShipmentCategoriesDto` |
| Feature 固有型 | 手動定義 | `FetchItemUnitsQuery`, `CreateItemUnitRequest` |

API 型を手動で定義しない。`yarn api:build` で Swagger から再生成。

## テスト: Vitest

```typescript
// src/features/dcs/components/DcSelect/DcSelect.test.tsx
import { render } from '@testing-library/react'
import { describe, expect, it } from 'vitest'

describe('DcSelect', () => {
  it('レンダリングできる', () => {
    const { container } = render(
      <DcSelect value={undefined} options={[makeDc(1, 'DC01', '東京')]} />,
    )
    expect(container.querySelector('.ant-select')).toBeTruthy()
  })

  it('選択値のcode/nameが表示される', () => {
    const { container } = render(
      <DcSelect value={1} options={[makeDc(1, 'DC01', '東京'), makeDc(2, 'DC02', '大阪')]} />,
    )
    expect(container.textContent).toContain('DC01/東京')
  })
})
```

パターン:
- `@testing-library/react` の `render()` でコンポーネントテスト
- DOM クエリ: `container.querySelector()`, `container.textContent`
- テスト実行: `yarn test`（watch）, `yarn test:coverage`

## Provider チェーン

`src/providers/app-provider.tsx` でネスト:

```
HelmetProvider > QueryClientProvider > AntdProvider > Content + Toaster
```

新しい Provider を追加する場合はこのファイルに追加する。

## 実装チェックリスト

### コード書く前
- [ ] `logi-go-frontend/CLAUDE.md` を読んだ
- [ ] 既存の類似 feature モジュールのパターンを確認した
- [ ] aspida 生成型（`src/libs/api/aspida/`）で使える型を確認した

### Feature モジュール
- [ ] `api/` — API 呼び出し関数（tenantKey + signal 対応）
- [ ] `query-keys.ts` — Query キー定義
- [ ] `query-options/` — queryKey + queryFn
- [ ] `models/` — Valibot スキーマ + `InferOutput` 型 + 初期値

### コンポーネント
- [ ] TypeScript で Props 型定義
- [ ] Ant Design コンポーネントをベースに使用
- [ ] Tailwind で微調整（自前 CSS 禁止）
- [ ] `Controller` + `Form.Item` でフォームフィールド

### データフェッチ
- [ ] TanStack Query の `useQuery` / `useMutation` 使用
- [ ] loading / error 状態をハンドリング
- [ ] mutation 成功時にキャッシュ更新 or `invalidateQueries`
- [ ] toast でユーザーフィードバック

### 状態管理
- [ ] サーバーデータは TanStack Query
- [ ] URL 状態は Router search params
- [ ] 共有 UI 状態のみ Jotai atom
