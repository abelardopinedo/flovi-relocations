<script setup lang="ts">
import { useRouter } from 'vue-router'
import { useAuth } from '../composables/useAuth'

const router = useRouter()
const { user, signOut } = useAuth()

async function handleSignOut() {
  await signOut()
  router.push({ name: 'login' })
}
</script>

<template>
  <main class="flex min-h-screen items-center justify-center bg-gray-50">
    <div class="w-full max-w-sm rounded-xl bg-white p-8 text-center shadow-sm">
      <h1 class="text-2xl font-semibold text-gray-900">Dispatcher App</h1>

      <div v-if="user" class="mt-6">
        <p class="text-sm text-gray-500">Signed in as</p>
        <p class="mt-1 font-medium text-gray-900">
          {{ user.user_metadata?.full_name ?? user.email }}
        </p>
        <p v-if="user.user_metadata?.full_name" class="text-sm text-gray-500">
          {{ user.email }}
        </p>

        <button
          type="button"
          class="mt-6 w-full rounded-lg border border-gray-300 px-4 py-2.5 text-sm font-medium text-gray-700 transition hover:bg-gray-50"
          @click="handleSignOut"
        >
          Sign out
        </button>
      </div>
    </div>
  </main>
</template>
