import { createRouter, createWebHistory } from 'vue-router'
import HomeView from '../views/HomeView.vue'
import LoginView from '../views/LoginView.vue'
import { authReady, useAuth } from '../composables/useAuth'

const router = createRouter({
  history: createWebHistory(import.meta.env.BASE_URL),
  routes: [
    {
      path: '/',
      name: 'home',
      component: HomeView,
    },
    {
      path: '/login',
      name: 'login',
      component: LoginView,
    },
  ],
})

router.beforeEach(async (to) => {
  console.log('[router] guard start, navigating to:', to.fullPath, 'awaiting authReady...')
  await authReady

  const { user } = useAuth()
  console.log('[router] authReady resolved, user:', user.value?.email ?? null)

  if (to.name !== 'login' && !user.value) {
    console.log('[router] no user -> redirecting to /login')
    return { name: 'login' }
  }

  if (to.name === 'login' && user.value) {
    console.log('[router] user present on /login -> redirecting to /')
    return { name: 'home' }
  }
})

export default router
