<script setup lang="ts">
import { useAuth } from '../composables/useAuth'

const { signInWithGoogle } = useAuth()
</script>

<template>
  <main class="flex min-h-screen items-center justify-center bg-gray-50">
    <div class="w-full max-w-sm rounded-xl bg-white p-8 text-center shadow-sm">
      <h1 class="text-2xl font-semibold text-gray-900">Dispatcher App</h1>
      <p class="mt-2 text-sm text-gray-500">Sign in to manage relocation requests.</p>

      <button
        type="button"
        class="mt-6 flex w-full items-center justify-center gap-3 rounded-lg border border-gray-300 px-4 py-2.5 text-sm font-medium text-gray-700 transition hover:bg-gray-50"
        @click="signInWithGoogle"
      >
        <svg class="h-5 w-5" viewBox="0 0 24 24">
          <path
            fill="#4285F4"
            d="M23.52 12.27c0-.85-.08-1.67-.22-2.45H12v4.64h6.47a5.53 5.53 0 0 1-2.4 3.63v3h3.87c2.27-2.09 3.58-5.17 3.58-8.82Z"
          />
          <path
            fill="#34A853"
            d="M12 24c3.24 0 5.95-1.07 7.94-2.91l-3.87-3c-1.07.72-2.45 1.15-4.07 1.15-3.13 0-5.78-2.11-6.73-4.96H1.27v3.11A12 12 0 0 0 12 24Z"
          />
          <path
            fill="#FBBC05"
            d="M5.27 14.28A7.2 7.2 0 0 1 4.89 12c0-.79.14-1.56.38-2.28V6.61H1.27A12 12 0 0 0 0 12c0 1.94.46 3.77 1.27 5.39l4-3.11Z"
          />
          <path
            fill="#EA4335"
            d="M12 4.75c1.77 0 3.35.61 4.6 1.8l3.44-3.44C17.94 1.19 15.24 0 12 0A12 12 0 0 0 1.27 6.61l4 3.11C6.22 6.86 8.87 4.75 12 4.75Z"
          />
        </svg>
        Sign in with Google
      </button>
    </div>
  </main>
</template>
