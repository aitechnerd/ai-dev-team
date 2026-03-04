# React + TypeScript Stack Profile

## Package Manager
- npm (package.json, package-lock.json) or yarn (yarn.lock) or pnpm (pnpm-lock.yaml)
- Check which: lockfile present determines the manager

## Build & Run
- Dev: `npm run dev` or `yarn dev` (Vite), `npm start` (CRA/webpack)
- Build: `npm run build`
- Preview: `npm run preview` (Vite)
- Bundler: check for vite.config.ts, webpack.config.js, next.config.js

## Testing
- Framework: Jest, Vitest (Vite projects), or Playwright/Cypress (E2E)
- Run: `npm test`, `npx vitest`, `npx jest`
- Single: `npx vitest run src/components/Button.test.tsx`
- React Testing Library: `@testing-library/react` — test behavior not implementation
- MSW: `msw` for API mocking in tests
- Coverage: `npx vitest --coverage` or `npx jest --coverage`
- Convention: `*.test.tsx` or `*.spec.tsx` colocated with components, or `__tests__/`

## Linting & Formatting
- Linter: ESLint — `npx eslint . --format json`
- Formatter: Prettier — `npx prettier --check .`
- TypeScript: `npx tsc --noEmit` (type check without build)
- Config: `.eslintrc.*`, `prettier.config.*`, `tsconfig.json`

## Security Scanners
- `npm audit` — known CVEs in npm packages (built-in)
  Run: `npm audit --json`
- ESLint + eslint-plugin-security — security-specific lint rules
- Semgrep — has TypeScript/React rules
- Gitleaks / Trivy — secrets + dependency CVEs

## Common Vulnerabilities
- XSS: avoid `dangerouslySetInnerHTML`, sanitize any user HTML with DOMPurify
- Open redirect: validate redirect URLs
- Sensitive data in client: never put secrets, API keys, or tokens in client bundle
- localStorage for auth tokens: vulnerable to XSS — prefer httpOnly cookies
- CORS: understand server CORS config, don't use wildcard in production
- Prototype pollution: lodash.merge, deep-extend with user objects
- Dependency supply chain: review new deps, check bundle size, known vulns
- Environment variables: only `VITE_*` or `REACT_APP_*` are bundled into client

## Dependencies
- Lockfile: always commit (package-lock.json, yarn.lock, pnpm-lock.yaml)
- Audit: `npm audit`, `npm audit fix`
- Outdated: `npm outdated`
- Bundle size: `npx bundlephobia` or import cost VS Code extension

## DevOps
- Docker: `node:xx-alpine`, multi-stage (build → nginx/static serve)
- CI: `npm ci` → `tsc --noEmit` → `eslint` → `test` → `build` → deploy
- Static hosting: Vercel, Netlify, Cloudflare Pages, S3+CloudFront
- SSR: Next.js, Remix — different deploy requirements
- CDN: static assets should be cache-busted (content hash in filename)

## Architecture Patterns
- Component structure: `components/`, `pages/` or `routes/`, `hooks/`, `utils/`
- State: React Query/TanStack Query for server state, zustand/jotai for client state
- Forms: React Hook Form or Formik + zod/yup for validation
- Routing: React Router or Next.js file-based routing
- API layer: centralized in `api/` or `services/`, typed with generated clients
- Error boundaries: wrap route segments, provide fallback UI
- Suspense: for async data loading patterns

## Code Review Focus
- Unnecessary re-renders: missing `useMemo`, `useCallback`, bad dependency arrays
- useEffect: missing cleanup, missing deps, infinite loops
- Key prop: using index as key in dynamic lists
- Type safety: `any` usage, missing type definitions
- Error handling: unhandled promise rejections, missing error boundaries
- Accessibility: missing labels, roles, keyboard navigation
- Bundle size: importing entire libraries vs tree-shaking
