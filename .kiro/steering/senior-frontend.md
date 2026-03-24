---
inclusion: fileMatch
fileMatchPattern: ['**/*.tsx', '**/*.jsx', '**/*.ts', '**/*.js', '**/*.css', '**/*.scss', '**/tailwind.config.*', '**/next.config.*']
---

# Senior Frontend Engineer

Patterns and conventions for React/Next.js applications using TypeScript and Tailwind CSS.

---

## Project Structure

Follow this layout for Next.js App Router projects:

```
app/
  layout.tsx          # Root layout (fonts, providers)
  page.tsx            # Route entry points
  globals.css         # Tailwind base + CSS variables
  api/*/route.ts      # API routes
components/
  ui/                 # Primitive components (Button, Input, Card)
  layout/             # Structural components (Header, Footer, Sidebar)
hooks/                # Custom hooks (useDebounce, useLocalStorage)
lib/                  # Utilities (cn), constants, API clients
types/                # Shared TypeScript interfaces and types
```

---

## Component Conventions

- Use named exports for all components.
- Define props with a TypeScript interface above the component.
- Use `cn()` from `lib/utils` (clsx + tailwind-merge) for conditional class merging.
- Prefer composition over prop drilling; use context or compound components for deep trees.
- Keep components focused — if a component does more than one thing, split it.

```tsx
'use client';

import { cn } from '@/lib/utils';

interface ButtonProps {
  variant?: 'primary' | 'secondary' | 'ghost';
  className?: string;
  children?: React.ReactNode;
  onClick?: () => void;
}

export function Button({ variant = 'primary', className, children, onClick }: ButtonProps) {
  return (
    <button
      onClick={onClick}
      className={cn(
        'px-4 py-2 rounded-md font-medium transition-colors',
        variant === 'primary' && 'bg-blue-600 text-white hover:bg-blue-700',
        variant === 'secondary' && 'bg-gray-100 text-gray-900 hover:bg-gray-200',
        variant === 'ghost' && 'hover:bg-gray-100',
        className
      )}
    >
      {children}
    </button>
  );
}
```

---

## Server vs Client Components

Default to Server Components. Add `'use client'` only when the component needs:
- React hooks (`useState`, `useEffect`, etc.)
- Browser APIs
- Event listeners

```tsx
// Server Component — direct data access, no interactivity
async function ProductList() {
  const products = await db.products.findMany();
  return <ul>{products.map(p => <ProductItem key={p.id} product={p} />)}</ul>;
}

// Client Component — interactivity required
'use client';
function AddToCartButton({ productId }: { productId: string }) {
  const [loading, setLoading] = useState(false);
  return <button onClick={() => addToCart(productId)}>Add to Cart</button>;
}
```

Push `'use client'` boundaries as far down the tree as possible to maximize server rendering.

---

## Performance

- Use `next/image` for all images; always provide `width`, `height`, and `alt`.
- Use `dynamic()` with a loading fallback for heavy components not needed on initial render.
- Prefer named imports over barrel imports to enable tree-shaking (e.g., `import debounce from 'lodash/debounce'`, not `import _ from 'lodash'`).
- Set `export const revalidate` on routes that can be cached.

```tsx
import Image from 'next/image';
<Image src="/hero.jpg" alt="Hero image" width={1200} height={600} priority />

const HeavyChart = dynamic(() => import('@/components/HeavyChart'), {
  loading: () => <Skeleton />,
  ssr: false,
});
```

Analyze bundle size with `ANALYZE=true npm run build` (requires `@next/bundle-analyzer`).

---

## Custom Hooks

Extract reusable stateful logic into hooks in `hooks/`. Each hook should have a single responsibility.

```tsx
function useDebounce<T>(value: T, delay: number): T {
  const [debouncedValue, setDebouncedValue] = useState(value);
  useEffect(() => {
    const timer = setTimeout(() => setDebouncedValue(value), delay);
    return () => clearTimeout(timer);
  }, [value, delay]);
  return debouncedValue;
}

function useLocalStorage<T>(key: string, initialValue: T) {
  const [value, setValue] = useState<T>(() => {
    try {
      const item = window.localStorage.getItem(key);
      return item ? JSON.parse(item) : initialValue;
    } catch { return initialValue; }
  });
  const setStoredValue = (val: T) => {
    setValue(val);
    window.localStorage.setItem(key, JSON.stringify(val));
  };
  return [value, setStoredValue] as const;
}
```

---

## Accessibility

Every component must meet these requirements:

- Images: descriptive `alt` text (empty string `alt=""` for decorative images).
- Interactive elements: keyboard navigable with visible focus indicators.
- Color contrast: WCAG AA minimum (4.5:1 for normal text, 3:1 for large text).
- Form inputs: associated `<label>` elements; errors linked via `aria-describedby`.
- Modals: trap focus on open, restore focus on close.
- Use semantic HTML (`<nav>`, `<main>`, `<section>`, `<article>`, `<button>`) over generic `<div>`.

---

## Testing

Use Vitest + Testing Library. Test behavior, not implementation.

- Query by role or label text, not by class or test ID.
- Prefer `userEvent` over `fireEvent` for realistic interaction simulation.
- Test edge cases: empty states, loading states, error states.

```tsx
import { render, screen } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import { Button } from './Button';

describe('Button', () => {
  it('renders with label', () => {
    render(<Button>Click me</Button>);
    expect(screen.getByRole('button', { name: /click me/i })).toBeInTheDocument();
  });

  it('calls onClick when clicked', async () => {
    const handleClick = vi.fn();
    render(<Button onClick={handleClick}>Click</Button>);
    await userEvent.click(screen.getByRole('button'));
    expect(handleClick).toHaveBeenCalledTimes(1);
  });
});
```

---

## TypeScript Rules

- Avoid `any`; use `unknown` and narrow with type guards.
- Define shared types in `types/`; co-locate component-specific types with the component.
- Use `interface` for object shapes, `type` for unions and utility types.
- Enable strict mode in `tsconfig.json`.
