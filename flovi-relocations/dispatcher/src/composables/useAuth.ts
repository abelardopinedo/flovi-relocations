import { ref } from 'vue'
import type { User } from '@supabase/supabase-js'
import { supabase } from '../lib/supabase'

const user = ref<User | null>(null)
const loading = ref(true)

console.log('[useAuth] module init, current URL:', window.location.href)

let resolveAuthReady: () => void
export const authReady = new Promise<void>((resolve) => {
  resolveAuthReady = resolve
})

// Registered before getSession() resolves so we never miss the SIGNED_IN
// event fired while the OAuth redirect is still being processed.
supabase.auth.onAuthStateChange((event, session) => {
  console.log('[useAuth] onAuthStateChange fired:', event, 'session present:', !!session)
  user.value = session?.user ?? null
  loading.value = false
})

supabase.auth.getSession().then(({ data, error }) => {
  console.log(
    '[useAuth] initial getSession() resolved, session present:',
    !!data.session,
    'error:',
    error,
  )
  user.value = data.session?.user ?? null
  loading.value = false
  resolveAuthReady()
})

async function signInWithGoogle() {
  console.log('[useAuth] signInWithGoogle called, redirecting to Google...')
  const { error } = await supabase.auth.signInWithOAuth({
    provider: 'google',
    options: {
      redirectTo: window.location.origin,
    },
  })
  if (error) {
    console.error('[useAuth] signInWithOAuth error:', error)
    throw error
  }
}

async function signOut() {
  const { error } = await supabase.auth.signOut()
  if (error) throw error
}

export function useAuth() {
  return { user, loading, signInWithGoogle, signOut }
}
