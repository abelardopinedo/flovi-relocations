<script setup lang="ts">
import { onMounted, ref } from 'vue'
import { useRouter } from 'vue-router'
import { useAuth } from '../composables/useAuth'
import { useRequests } from '../composables/useRequests'
import type { RelocationRequest } from '../composables/useRequests'
import RequestFormModal from '../components/RequestFormModal.vue'

const router = useRouter()
const { user, signOut } = useAuth()
const { requests, loading, error, fetchRequests } = useRequests()

const isModalOpen = ref(false)
const editingRequest = ref<RelocationRequest | null>(null)

onMounted(() => {
  fetchRequests()
})

function openCreateModal() {
  editingRequest.value = null
  isModalOpen.value = true
}

function openEditModal(request: RelocationRequest) {
  editingRequest.value = request
  isModalOpen.value = true
}

function closeModal() {
  isModalOpen.value = false
  editingRequest.value = null
}

async function handleSignOut() {
  await signOut()
  router.push({ name: 'login' })
}

function formatDate(dateString: string) {
  return new Date(`${dateString}T00:00:00`).toLocaleDateString(undefined, {
    year: 'numeric',
    month: 'short',
    day: 'numeric',
  })
}

const statusStyles: Record<RelocationRequest['status'], string> = {
  open: 'bg-gray-100 text-gray-700',
  booked: 'bg-green-100 text-green-700',
  completed: 'bg-blue-100 text-blue-700',
}
</script>

<template>
  <div class="min-h-screen bg-gray-50">
    <header class="border-b border-gray-200 bg-white">
      <div class="mx-auto flex max-w-5xl items-center justify-between px-6 py-4">
        <h1 class="text-lg font-semibold text-gray-900">Dispatcher App</h1>
        <div class="flex items-center gap-4">
          <span class="text-sm text-gray-500">{{
            user?.user_metadata?.full_name ?? user?.email
          }}</span>
          <button
            type="button"
            class="rounded-lg border border-gray-300 px-3 py-1.5 text-sm font-medium text-gray-700 transition hover:bg-gray-50"
            @click="handleSignOut"
          >
            Sign out
          </button>
        </div>
      </div>
    </header>

    <main class="mx-auto max-w-5xl px-6 py-8">
      <div class="flex items-center justify-between">
        <h2 class="text-xl font-semibold text-gray-900">Relocation Requests</h2>
        <button
          type="button"
          class="rounded-lg bg-indigo-600 px-4 py-2 text-sm font-medium text-white transition hover:bg-indigo-500"
          @click="openCreateModal"
        >
          New Request
        </button>
      </div>

      <p v-if="error" class="mt-4 rounded-lg bg-red-50 px-4 py-3 text-sm text-red-700">
        {{ error }}
      </p>

      <div class="mt-6 overflow-hidden rounded-xl border border-gray-200 bg-white shadow-sm">
        <div v-if="loading && requests.length === 0" class="p-8 text-center text-sm text-gray-500">
          Loading requests...
        </div>

        <div
          v-else-if="requests.length === 0"
          class="p-8 text-center text-sm text-gray-500"
        >
          No relocation requests yet. Create one to get started.
        </div>

        <table v-else class="min-w-full divide-y divide-gray-200">
          <thead class="bg-gray-50">
            <tr>
              <th class="px-6 py-3 text-left text-xs font-medium uppercase tracking-wider text-gray-500">
                Origin
              </th>
              <th class="px-6 py-3 text-left text-xs font-medium uppercase tracking-wider text-gray-500">
                Destination
              </th>
              <th class="px-6 py-3 text-left text-xs font-medium uppercase tracking-wider text-gray-500">
                Date
              </th>
              <th class="px-6 py-3 text-left text-xs font-medium uppercase tracking-wider text-gray-500">
                Status
              </th>
              <th class="px-6 py-3"></th>
            </tr>
          </thead>
          <tbody class="divide-y divide-gray-200">
            <tr v-for="request in requests" :key="request.id">
              <td class="px-6 py-4 text-sm text-gray-900">{{ request.origin }}</td>
              <td class="px-6 py-4 text-sm text-gray-900">{{ request.destination }}</td>
              <td class="px-6 py-4 text-sm text-gray-500">{{ formatDate(request.move_date) }}</td>
              <td class="px-6 py-4">
                <span
                  class="inline-flex rounded-full px-2.5 py-0.5 text-xs font-medium capitalize"
                  :class="statusStyles[request.status]"
                >
                  {{ request.status }}
                </span>
              </td>
              <td class="px-6 py-4 text-right">
                <button
                  type="button"
                  class="rounded-lg border border-gray-300 px-3 py-1.5 text-sm font-medium text-gray-700 transition hover:bg-gray-50"
                  @click="openEditModal(request)"
                >
                  Edit
                </button>
              </td>
            </tr>
          </tbody>
        </table>
      </div>
    </main>

    <RequestFormModal :open="isModalOpen" :request="editingRequest" @close="closeModal" />
  </div>
</template>
