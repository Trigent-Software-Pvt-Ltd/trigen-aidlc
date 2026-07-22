---
owner: Architecture Guild
last-reviewed: 2026-02-27
scope: Vue 3 frontend projects
detection-markers:
  - package.json with "vue" dependency
  - vite.config.ts or vite.config.js
  - "*.vue" files
  - src/main.ts with createApp()
---

# Vue Project-Type Technical Guidance

Architectural standards for Vue 3 frontend projects. These extend the Global Technical Guidance.

## How to Use This Guidance

- Applies when project contains Vue markers (package.json with vue, *.vue files, vite.config)
- Extends Global Guidance; does not replace it
- Project-level guidance in the Intent doc may override specific standards
- Deviations require an ADR documenting the rationale

---

## New Project Setup

> **Note:** There is currently no Trigent Vue scaffold template project. For
> greenfield Vue projects, initialise using the official Vite scaffold and then
> apply the conventions in this document.

### Initialise with Vite

```bash
# Create a new Vue + TypeScript project
yarn create vite@latest <project-name> -- --template vue-ts
cd <project-name>
yarn install
```

### Required Configuration After Scaffolding

Apply these changes immediately after scaffolding before writing any feature code:

1. **`.nvmrc`** — Add to repo root with the target Node version (see Vue & Node Version section)
2. **`yarn.lock`** — Commit the lock file; do not use npm or pnpm
3. **Pinia** — `yarn add pinia`
4. **Vue Router** — `yarn add vue-router`; configure file-based routing with `unplugin-vue-router` or manual routes
5. **Auth0** — `yarn add @auth0/auth0-vue`; set up singleton (see Authentication section)
6. **Feather UI** — `yarn add @trigent/feather-ui`; configure Vite SCSS (see UI Components section)
7. **Vitest** — `yarn add -D vitest @vue/test-utils @pinia/testing`; configure in `vite.config.ts`
8. **Playwright** — `yarn create playwright`
9. **ESLint + Prettier** — Configure per the Code Quality section
10. **Husky + commitlint** — Add pre-commit hooks for lint and commit message validation
11. **`env/`** — Create environment files per the Environment Configuration section; do **not** use `.env` at root

---

## Vue & Node Version

| Standard | Requirement |
|----------|-------------|
| Vue version | 3.5+ for new projects; 3.3+ minimum for existing |
| Node version | 22 LTS+ for new projects; 20 LTS+ minimum for existing |
| Package manager | yarn |
| Build tool | Vite 6+ for new projects; Vite 5+ minimum for existing |
| Version files | `.nvmrc` or `.node-version` required at repo root |

### Version File

Include `.nvmrc` in repo root:

```
22
```

---

## Project Structure

### Standard Vue Layout

| Standard | Requirement |
|----------|-------------|
| API style | Composition API with `<script setup>` syntax |
| State management | Pinia stores in `src/stores/` |
| Naming | kebab-case for Vue files and directories; PascalCase for components in templates |
| TypeScript | Required for all new projects |

### Recommended Structure

```
src/
  assets/              # Static assets (images, fonts, sample data)
  components/          # Reusable Vue components
  composables/         # Vue Composition API functions (useXxx) — setup() context only
  constants/           # Centralized constants and enums
  fixtures/            # Test fixtures and mock data
  layouts/             # Layout components (main-layout, auth-layout)
  pages/               # File-based routing (auto-generated routes)
  router/              # Route configuration and guards
  services/            # API service layer
  stores/              # Pinia state stores
  types/               # TypeScript type definitions
  utils/               # Pure TypeScript helpers with no Vue dependency
  App.vue              # Root application component
  main.ts              # Application entry point
e2e/                   # Playwright end-to-end tests
env/                   # Environment configuration files
```

### Composables vs Utils

Keep these directories strictly separated — they have different constraints:

| | `composables/` | `utils/` |
|---|---|---|
| Contents | Functions using Vue reactivity (`ref`, `computed`, `watch`, lifecycle hooks) | Pure TypeScript functions with no Vue dependency |
| Naming | `useXxx` convention | Any name |
| Where callable | Inside `setup()`, `<script setup>`, or other composables only | Anywhere — components, stores, services, tests |
| Examples | `useWindowSize`, `useDebounce`, `usePagination` | `formatDate`, `slugify`, `parseApiError` |

> **Why it matters:** A function in `utils/` signals it is safe to call anywhere. If a composable ends up there, callers have no warning that it requires a Vue instance — this leads to runtime errors that are difficult to trace. The `useFetch` pattern in this document is a deliberate exception: it is a composable but belongs in `utils/` because it wraps the fetch infrastructure rather than encapsulating reactive UI state. Document exceptions like this with a comment.

### File Naming Conventions

| Type | Pattern | Example |
|------|---------|---------|
| Components | `{name}.vue` (kebab-case) | `configuration-selector.vue` |
| Pages | `{route-segment}.vue` | `client-selector.vue` |
| Composables | `use{Name}.ts` (camelCase) | `usePagination.ts` |
| Stores | `{domain}Store.ts` | `studentsStore.ts` |
| Services | `{domain}-service.ts` | `students-service.ts` |
| Utils | `{name}.ts` (kebab-case) | `format-date.ts` |
| Types | `{domain}-model.ts` | `student-model.ts` |
| Constants | `{domain}-constants.ts` | `permission-constants.ts` |

---

## Component Patterns

### Script Setup Style

All components must use `<script setup>` with TypeScript:

```vue
<script setup lang="ts">
import { ref, computed, onMounted } from 'vue';
import { storeToRefs } from 'pinia';
import { useStudentsStore } from '@/stores/studentsStore';

// Props with TypeScript
interface Props {
  studentId: string;
  isEditable?: boolean;
}

const props = withDefaults(defineProps<Props>(), {
  isEditable: false
});

// Emits with TypeScript
const emit = defineEmits<{
  'update:student': [student: StudentModel];
  'delete': [id: string];
}>();

// Store access
const studentsStore = useStudentsStore();
const { students, isLoading } = storeToRefs(studentsStore);

// Local state
const searchTerm = ref('');

// Computed
const filteredStudents = computed(() =>
  students.value.filter(s => s.name.includes(searchTerm.value))
);

// Lifecycle
onMounted(() => {
  studentsStore.fetchStudents();
});
</script>
```

### Component Standards

| Standard | Requirement |
|----------|-------------|
| Props | Typed with TypeScript interfaces; use `withDefaults` for default values |
| Emits | Typed with `defineEmits<{}>()` syntax |
| Store access | Use `storeToRefs()` to maintain reactivity when destructuring |
| Local state | Use `ref()` for primitives, `reactive()` for complex objects |
| Lifecycle | Use Composition API hooks (`onMounted`, `onUnmounted`, etc.) |

### Component Composition

| Standard | Requirement |
|----------|-------------|
| Single responsibility | One component, one purpose; extract reusable logic to composables |
| Props down, events up | Pass data via props; communicate changes via emits |
| Scoped styles | Use `<style scoped lang="scss">` for component styles |
| Template refs | Use typed refs: `const inputRef = ref<HTMLInputElement>()` |

---

## State Management

### Pinia Stores

All state management uses Pinia with Composition API syntax:

```typescript
import { defineStore } from 'pinia';
import { ref, computed, reactive } from 'vue';
import { cloneDeep } from 'lodash';

interface StudentState {
  students: StudentModel[];
  selectedStudent: StudentModel | null;
  isLoading: boolean;
  error: string | null;
}

const initialState: StudentState = {
  students: [],
  selectedStudent: null,
  isLoading: false,
  error: null
};

export const useStudentsStore = defineStore('students', () => {
  // State - use reactive for objects, ref for primitives
  const state = reactive(cloneDeep(initialState));

  // Getters
  const studentCount = computed(() => state.students.length);
  const hasError = computed(() => state.error !== null);

  // Actions
  async function fetchStudents(clientId: string) {
    state.isLoading = true;
    state.error = null;
    try {
      state.students = await studentsService.fetchStudents(clientId);
    } catch (e) {
      state.error = e instanceof ApiError ? e.message : 'Failed to fetch students';
    } finally {
      state.isLoading = false;
    }
  }

  function reset() {
    Object.assign(state, cloneDeep(initialState));
  }

  return {
    // State (exposed as refs for reactivity)
    ...toRefs(state),
    // Getters
    studentCount,
    hasError,
    // Actions
    fetchStudents,
    reset
  };
});
```

### Store Standards

| Standard | Requirement |
|----------|-------------|
| Store style | Composition API (function syntax) with `defineStore` |
| Initial state | Deep clone initial state to prevent mutation; expose reset function |
| Error handling | Store error state; let components decide how to display |
| Loading state | Track loading state per operation or globally per store |
| Naming | `use{Domain}Store` function name; `{domain}` store ID |

### Store Anti-Patterns to Avoid

```typescript
// BAD: Mutating store state directly in components
studentsStore.students.push(newStudent);

// GOOD: Use store actions
studentsStore.addStudent(newStudent);

// BAD: Destructuring without storeToRefs (loses reactivity)
const { students } = studentsStore;

// GOOD: Use storeToRefs for reactive destructuring
const { students } = storeToRefs(studentsStore);
```

---

## Routing

### File-Based Routing

Use `unplugin-vue-router` for automatic route generation from the `pages/` directory:

```
src/pages/
  index.vue                           → /
  client-selector.vue                 → /client-selector
  client/
    admin/
      settings/
        index.vue                     → /client/admin/settings
        [id].vue                      → /client/admin/settings/:id
  [...notfound].vue                   → /* (catch-all 404)
```

### Route Guards

```typescript
// router/permissions-guard.ts
import { useAppContextStore } from '@/stores/appContextStore';
import type { NavigationGuard } from 'vue-router';

export const permissionsGuard: NavigationGuard = (to, from, next) => {
  const appContext = useAppContextStore();
  const requiredPermissions = to.meta.permissions as string[] | undefined;

  if (!requiredPermissions || requiredPermissions.length === 0) {
    return next();
  }

  const hasPermission = requiredPermissions.some(
    permission => appContext.permissions.includes(permission)
  );

  if (hasPermission) {
    return next();
  }

  // Redirect to unauthorized page or external URL
  return next({ name: 'unauthorized' });
};
```

### Route Configuration

```typescript
// router/index.ts
import { createRouter, createWebHistory } from 'vue-router';
import { routes } from 'vue-router/auto-routes';
import { authGuard } from '@auth0/auth0-vue';
import { permissionsGuard } from './permissions-guard';

const router = createRouter({
  history: createWebHistory(import.meta.env.BASE_URL),
  routes
});

// Auth guard: protect all routes that require authentication.
// Do NOT use `router.beforeEach(authGuard)` directly — it will intercept
// the Auth0 callback route and cause an infinite redirect loop.
// Instead, opt routes out via `meta.requiresAuth: false`.
router.beforeEach(async (to, from, next) => {
  if (to.meta.requiresAuth === false) {
    return next();
  }
  return authGuard(to, from, next);
});

router.beforeEach(permissionsGuard);

export default router;
```

```typescript
// Route meta type declaration (e.g. in router/index.ts or types/router.d.ts)
declare module 'vue-router' {
  interface RouteMeta {
    requiresAuth?: boolean;
    permissions?: string[];
  }
}
```

### Routing Standards

| Standard | Requirement |
|----------|-------------|
| Routing style | File-based routing via `unplugin-vue-router` |
| Authentication | Auth0 guard on all routes; opt out via `meta.requiresAuth: false` for public routes |
| Authorization | Permission-based guards; define required permissions in route meta |
| 404 handling | Catch-all route with `[...notfound].vue` |

---

## API Integration

### Fetch Utility

Use `@vueuse/core` `createFetch` for composable HTTP client. The Auth0 instance
must be accessed via the singleton exported from `utils/auth0.ts` — do **not**
call `useAuth0()` here, as Vue composables cannot be called outside a component
`setup()` context.

```typescript
// utils/auth0.ts — create and export the Auth0 singleton
import { createAuth0 } from '@auth0/auth0-vue';
import { config } from '@/config/env';

const auth0 = createAuth0({
  domain: config.auth0.domain,
  clientId: config.auth0.clientId,
  authorizationParams: {
    redirect_uri: window.location.origin,
    audience: config.auth0.audience
  }
});

export default auth0;
```

```typescript
// main.ts — register the singleton with the app
import auth0 from '@/utils/auth0';
app.use(auth0);
```

```typescript
// utils/fetch.ts — use the singleton, not useAuth0()
import { createFetch } from '@vueuse/core';
import auth0 from '@/utils/auth0';

export const useFetch = createFetch({
  baseUrl: import.meta.env.VITE_API_BASE_URL,
  options: {
    async beforeFetch({ options }) {
      const token = await auth0.getAccessTokenSilently();
      options.headers = {
        ...options.headers,
        Authorization: `Bearer ${token}`,
        'Content-Type': 'application/json'
      };
      return { options };
    },
    async afterFetch(ctx) {
      if (ctx.response.status === 401) {
        await auth0.loginWithRedirect();
      }
      return ctx;
    }
  }
});
```

### Service Layer Pattern

```typescript
// services/students-service.ts
import { useFetch } from '@/utils/fetch';
import { ApiError } from '@/types/api-error';
import type { StudentModel, CreateStudentRequest } from '@/types/student-model';

const BASE_PATH = '/api/v2/students';

export async function fetchStudents(clientId: string): Promise<StudentModel[]> {
  const { data, statusCode, error } = await useFetch(
    `${BASE_PATH}?clientId=${clientId}`
  ).get().json<StudentModel[]>();

  if (statusCode.value && statusCode.value >= 200 && statusCode.value < 300) {
    return data.value ?? [];
  }

  throw new ApiError(
    error.value?.message ?? 'Failed to fetch students',
    statusCode.value ?? 500
  );
}

export async function createStudent(
  clientId: string,
  request: CreateStudentRequest
): Promise<StudentModel> {
  const { data, statusCode, error } = await useFetch(
    `${BASE_PATH}?clientId=${clientId}`
  ).post(request).json<StudentModel>();

  if (statusCode.value === 201 && data.value) {
    return data.value;
  }

  throw new ApiError(
    error.value?.message ?? 'Failed to create student',
    statusCode.value ?? 500
  );
}
```

### API Standards

| Standard | Requirement |
|----------|-------------|
| HTTP client | `@vueuse/core` createFetch composable |
| Authentication | Automatic Bearer token injection via Auth0 |
| Error handling | Custom `ApiError` class; services throw, stores catch |
| Endpoints | Centralized in `utils/api-endpoints.ts` |
| Versioning | URL path versioning (`/api/v1/`, `/api/v2/`) |

---

## Authentication & Authorization

### Auth0 Integration

Create the Auth0 instance as a singleton in `utils/auth0.ts` (see API Integration
section), then register it in `main.ts`:

```typescript
// main.ts
import auth0 from '@/utils/auth0';
app.use(auth0);
```

This singleton pattern is required to use `getAccessTokenSilently()` outside of
Vue component context (e.g. in `fetch.ts`, route guards). Calling `useAuth0()`
outside `setup()` will throw a Vue warning at runtime.

### Permission Patterns

```typescript
// constants/permissions.ts
export const Permissions = {
  READ_STUDENTS: 'read:students',
  WRITE_STUDENTS: 'write:students',
  DELETE_STUDENTS: 'delete:students',
  ADMIN: 'admin:all'
} as const;

// Component usage
<template>
  <button v-if="canEdit" @click="editStudent">Edit</button>
</template>

<script setup lang="ts">
import { computed } from 'vue';
import { useAppContextStore } from '@/stores/appContextStore';
import { Permissions } from '@/constants/permissions';

const appContext = useAppContextStore();

const canEdit = computed(() =>
  appContext.permissions.includes(Permissions.WRITE_STUDENTS)
);
</script>
```

### Auth Standards

| Standard | Requirement |
|----------|-------------|
| Provider | Auth0 (`@auth0/auth0-vue`) |
| Token handling | Silent token refresh via `getAccessTokenSilently()` |
| Route protection | Auth0 guard on all authenticated routes |
| Permission checking | Check permissions in components and route guards |

---

## UI Components

### Feather UI Design System

Use `@trigent/feather-ui` as the primary component library:

```vue
<template>
  <FeatherButton @click="handleSave" :disabled="isLoading">
    Save
  </FeatherButton>
  <FeatherSpinner v-if="isLoading" />
  <FeatherModal v-model="showModal" title="Confirm Action">
    <p>Are you sure?</p>
  </FeatherModal>
</template>

<script setup lang="ts">
import {
  FeatherButton,
  FeatherSpinner,
  FeatherModal
} from '@trigent/feather-ui';
</script>
```

### Styling Standards

| Standard | Requirement |
|----------|-------------|
| Component library | `@trigent/feather-ui` |
| Custom styles | Scoped SCSS (`<style scoped lang="scss">`) |
| Global variables | Import via Vite SCSS `additionalData` from `@trigent/feather-ui/_base.scss` |
| Icons | Feather UI icon set |

### Vite SCSS Configuration

```typescript
// vite.config.ts
export default defineConfig({
  css: {
    preprocessorOptions: {
      scss: {
        // Use @import, not @use — Vite's additionalData prepends this to every
        // SCSS file, and @use rules must appear before any other content,
        // which causes build errors in most configurations.
        additionalData: `@import "@trigent/feather-ui/_base.scss";`
      }
    }
  }
});
```

---

## Feature Flags

### LaunchDarkly Integration

```typescript
// main.ts
import { LDPlugin } from 'launchdarkly-vue-client-sdk';

app.use(LDPlugin, {
  clientSideID: import.meta.env.VITE_LD_CLIENT_ID,
  user: {
    key: 'anonymous'
  }
});

// Component usage
<script setup lang="ts">
import { useLDFlag } from 'launchdarkly-vue-client-sdk';

const useNewApi = useLDFlag('use-v3-api', false);
</script>
```

### Local Development with ldcli dev-server

Use the `ldcli` dev-server to test flags locally without coordinating with other
developers or toggling flags in the shared LaunchDarkly environment.

**Install (requires v1.4.0+):**

```bash
brew tap launchdarkly/homebrew-tap && brew install ldcli
# or: npm install -g @launchdarkly/ldcli
```

**One-time setup:**

```bash
ldcli login                                              # authenticate
ldcli dev-server start                                   # start local server
ldcli dev-server add-project --project <project-key> --source <env-key>
# e.g. --source production  (copies flag values from that environment)
```

**Connect the Vue app to the local server:**

```typescript
// main.ts — dev-only config pointing to ldcli dev-server
import { LDPlugin } from 'launchdarkly-vue-client-sdk';

const isLocalDev = import.meta.env.VITE_LD_USE_DEV_SERVER === 'true';

app.use(LDPlugin, {
  clientSideID: isLocalDev
    ? import.meta.env.VITE_LD_PROJECT_KEY   // project key, not SDK key
    : import.meta.env.VITE_LD_CLIENT_ID,
  ...(isLocalDev && {
    options: {
      streamUrl: 'http://localhost:8765',
      baseUrl: 'http://localhost:8765',
      eventsUrl: 'http://localhost:8765'
    }
  })
});
```

Add to your local env file:

```bash
# env/.env.localdev
VITE_LD_USE_DEV_SERVER=true
VITE_LD_PROJECT_KEY=<your-launchdarkly-project-key>
```

**Override flag values for local testing:**

```bash
# Via CLI
ldcli dev-server add-override --project <project-key> --flag <flag-key> --data true

# Via UI
open http://localhost:8765/ui/
```

### Feature Flag Standards

| Standard | Requirement |
|----------|-------------|
| Provider | LaunchDarkly |
| Default values | Always provide fallback default values |
| User context | Update context when user/client changes |
| Cleanup | Remove flags after feature is fully rolled out |
| Local development | Use `ldcli dev-server` to override flags locally without touching shared environments |

---

## Testing

### Testing Framework

| Standard | Requirement |
|----------|-------------|
| Unit testing | Vitest with Vue Test Utils |
| E2E testing | Playwright |
| Coverage | 80%+ line coverage for components and services |
| Mocking | `createTestingPinia()` for store mocking |

### Test Organization

```
src/
  components/
    __tests__/
      configuration-selector.spec.ts
  services/
    tests/
      students-service.spec.ts
  utils/
    tests/
      fetch.spec.ts
e2e/
  auth.setup.ts
  students.spec.ts
```

### Component Test Pattern

```typescript
// components/__tests__/student-card.spec.ts
import { describe, it, expect, vi } from 'vitest';
import { mount } from '@vue/test-utils';
import { createTestingPinia } from '@pinia/testing';
import StudentCard from '../student-card.vue';

describe('StudentCard', () => {
  it('renders student name', () => {
    const wrapper = mount(StudentCard, {
      props: {
        student: { id: '1', name: 'John Doe' }
      },
      global: {
        plugins: [createTestingPinia()]
      }
    });

    expect(wrapper.text()).toContain('John Doe');
  });

  it('emits edit event when edit button clicked', async () => {
    const wrapper = mount(StudentCard, {
      props: {
        student: { id: '1', name: 'John Doe' },
        isEditable: true
      },
      global: {
        plugins: [createTestingPinia()]
      }
    });

    await wrapper.find('[data-testid="edit-button"]').trigger('click');

    expect(wrapper.emitted('edit')).toBeTruthy();
  });
});
```

### E2E Test Pattern

```typescript
// e2e/students.spec.ts
import { test, expect } from '@playwright/test';

test.describe('Students Page', () => {
  test.beforeEach(async ({ page }) => {
    // Authentication handled by auth.setup.ts
    await page.goto('/client/admin/students');
  });

  test('displays student list', async ({ page }) => {
    await expect(page.getByRole('table')).toBeVisible();
    await expect(page.getByRole('row')).not.toHaveCount(0);
  });

  test('can add new student', async ({ page }) => {
    await page.getByRole('button', { name: 'Add Student' }).click();
    await page.getByLabel('First Name').fill('Jane');
    await page.getByLabel('Last Name').fill('Doe');
    await page.getByRole('button', { name: 'Save' }).click();

    await expect(page.getByText('Student created')).toBeVisible();
  });
});
```

---

## Code Quality

### Linting Standards

| Standard | Requirement |
|----------|-------------|
| Linting | ESLint with Vue 3 and TypeScript plugins |
| Formatting | Prettier |
| Pre-commit | Husky hooks for lint and format checks |
| Commit messages | Conventional commits via commitlint |

### ESLint Configuration

```javascript
// .eslintrc.cjs
module.exports = {
  extends: [
    'eslint:recommended',
    'plugin:vue/vue3-essential',
    '@vue/eslint-config-typescript',
    '@vue/eslint-config-prettier'
  ],
  rules: {
    'vue/multi-word-component-names': 'off' // Allow single-word page names
  }
};
```

### Prettier Configuration

```json
{
  "printWidth": 110,
  "singleQuote": true,
  "trailingComma": "es5",
  "vueIndentScriptAndStyle": true
}
```

---

## Dependency Management

### Keeping Dependencies Current

Regularly update dependencies to include security patches and bug fixes:

| Standard | Requirement |
|----------|-------------|
| Update frequency | Check for minor/patch updates at the start of each bolt |
| Security audits | Run `yarn npm audit`; address high/critical issues promptly |
| Lock file | Commit `yarn.lock`; regenerate when updating |

### Routine Checks (AI-Assisted)

At the start of each bolt implementation, run:

```bash
# Run security audit (Yarn 4 syntax)
yarn npm audit

# Update a specific package to latest
yarn up <package-name>

# Update all packages (recursive across workspaces)
yarn up --recursive
```

Include any dependency updates in the bolt's commits when relevant patches or security fixes are available.

---

## Environment Configuration

### Environment Files

```
env/
  .env.localdev        # Local development
  .env.dev             # Dev environment
  .env.staging         # Staging environment
  .env.production      # Production environment
  .env.production.uk   # Region-specific variants
```

### Environment Variables

| Variable | Purpose |
|----------|---------|
| `VITE_API_BASE_URL` | Backend API base URL |
| `VITE_AUTH0_DOMAIN` | Auth0 tenant domain |
| `VITE_AUTH0_CLIENT_ID` | Auth0 application client ID |
| `VITE_AUTH0_AUDIENCE` | Auth0 API audience |
| `VITE_LD_CLIENT_ID` | LaunchDarkly client ID |

### Config Object Pattern

Map `import.meta.env` values to a config object for cleaner unit testing:

```typescript
// config/env.ts
export const config = {
  apiBaseUrl: import.meta.env.VITE_API_BASE_URL,
  auth0: {
    domain: import.meta.env.VITE_AUTH0_DOMAIN,
    clientId: import.meta.env.VITE_AUTH0_CLIENT_ID,
    audience: import.meta.env.VITE_AUTH0_AUDIENCE
  },
  launchDarkly: {
    clientId: import.meta.env.VITE_LD_CLIENT_ID
  }
} as const;
```

Usage throughout the app:

```typescript
// services/api-service.ts
import { config } from '@/config/env';

const baseUrl = config.apiBaseUrl;  // Not import.meta.env.VITE_API_BASE_URL
```

This allows tests to mock the config object without dealing with `import.meta.env`:

```typescript
// In tests
vi.mock('@/config/env', () => ({
  config: {
    apiBaseUrl: 'http://test-api',
    auth0: { domain: 'test', clientId: 'test', audience: 'test' }
  }
}));
```

### Build Output

Build outputs to mode-specific directories:

```bash
yarn build --mode production
# Output: dist/production/
```

---

## Module Federation

### Remote Component Sharing

```typescript
// vite.config.ts
import federation from '@originjs/vite-plugin-federation';

export default defineConfig({
  plugins: [
    federation({
      name: 'student-staff-ui',
      remotes: {
        platform_web_shared: import.meta.env.VITE_SHARED_REMOTE_URL
      },
      shared: ['vue', 'pinia', 'vue-router', '@trigent/feather-ui']
    })
  ]
});
```

### Module Federation Standards

| Standard | Requirement |
|----------|-------------|
| Shared dependencies | vue, pinia, vue-router, @trigent/feather-ui |
| Remote URLs | Configured via environment variables |
| Fallbacks | Graceful degradation if remote unavailable |

---

## Anti-Patterns to Avoid

| Anti-Pattern | Do This Instead |
|--------------|-----------------|
| Options API in new components | Use Composition API with `<script setup>` |
| Direct store state mutation | Use store actions |
| Destructuring stores without `storeToRefs` | Use `storeToRefs()` for reactive destructuring |
| Business logic in components | Extract to services or composables |
| Inline styles | Use scoped SCSS |
| Any types in TypeScript | Define proper interfaces and types |
| Hardcoded API URLs | Use environment variables |
| Console.log in production | Use proper logging or remove |

---

## Adding New Features

### New Feature Checklist

- [ ] Type definitions in `types/`
- [ ] Pinia store (if feature has state)
- [ ] Service layer for API calls
- [ ] Constants/enums if needed
- [ ] Page component in `pages/` (for routes)
- [ ] Reusable components in `components/`
- [ ] Route permissions in `router/route-permissions.ts`
- [ ] Unit tests for components and services
- [ ] E2E tests for critical paths
- [ ] Feature flag if gradual rollout needed
