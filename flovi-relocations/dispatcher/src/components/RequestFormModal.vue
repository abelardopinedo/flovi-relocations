<script setup lang="ts">
import { computed, onMounted, onUnmounted, reactive, ref, watch } from 'vue'
import { useRequests } from '../composables/useRequests'
import type { RelocationRequest } from '../composables/useRequests'

const props = defineProps<{
  open: boolean
  request?: RelocationRequest | null
}>()

const emit = defineEmits<{
  close: []
}>()

const { createRequest, updateRequest } = useRequests()

const isEditMode = computed(() => !!props.request)

const form = reactive({
  origin: '',
  destination: '',
  move_date: '',
  notes: '',
})

const errors = reactive({
  origin: '',
  destination: '',
  move_date: '',
})

const submitting = ref(false)
const submitError = ref<string | null>(null)

function resetForm() {
  form.origin = props.request?.origin ?? ''
  form.destination = props.request?.destination ?? ''
  form.move_date = props.request?.move_date ?? ''
  form.notes = props.request?.notes ?? ''
  errors.origin = ''
  errors.destination = ''
  errors.move_date = ''
  submitError.value = null
}

watch(
  () => props.open,
  (isOpen) => {
    if (isOpen) resetForm()
  },
)

function validate() {
  errors.origin = form.origin.trim() ? '' : 'Origin is required.'
  errors.destination = form.destination.trim() ? '' : 'Destination is required.'
  errors.move_date = form.move_date ? '' : 'Move date is required.'
  return !errors.origin && !errors.destination && !errors.move_date
}

async function handleSubmit() {
  if (!validate()) return

  submitting.value = true
  submitError.value = null

  try {
    const payload = {
      origin: form.origin.trim(),
      destination: form.destination.trim(),
      move_date: form.move_date,
      notes: form.notes.trim() || null,
    }

    if (props.request) {
      await updateRequest(props.request.id, payload)
    } else {
      await createRequest(payload)
    }

    emit('close')
  } catch (err) {
    submitError.value =
      err instanceof Error ? err.message : 'Something went wrong. Please try again.'
  } finally {
    submitting.value = false
  }
}

function handleKeydown(event: KeyboardEvent) {
  if (event.key === 'Escape' && props.open) {
    emit('close')
  }
}

onMounted(() => window.addEventListener('keydown', handleKeydown))
onUnmounted(() => window.removeEventListener('keydown', handleKeydown))
</script>

<template>
  <Transition name="modal">
    <div
      v-if="open"
      class="fixed inset-0 z-50 flex items-center justify-center bg-black/40 p-4"
      @click.self="emit('close')"
    >
      <div class="modal-panel w-full max-w-md rounded-xl bg-white p-6 shadow-lg">
        <div class="flex items-start justify-between">
          <h2 class="text-lg font-semibold text-gray-900">
            {{ isEditMode ? 'Edit Relocation Request' : 'New Relocation Request' }}
          </h2>
          <button
            type="button"
            class="rounded-md p-1 text-gray-400 transition hover:bg-gray-100 hover:text-gray-600"
            aria-label="Close"
            @click="emit('close')"
          >
            <svg class="h-5 w-5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path
                stroke-linecap="round"
                stroke-linejoin="round"
                stroke-width="2"
                d="M6 18L18 6M6 6l12 12"
              />
            </svg>
          </button>
        </div>

        <form class="mt-6 space-y-4" novalidate @submit.prevent="handleSubmit">
          <div>
            <label for="origin" class="block text-sm font-medium text-gray-700">Origin</label>
            <input
              id="origin"
              v-model="form.origin"
              type="text"
              placeholder="e.g. Chicago, IL"
              class="mt-1 block w-full rounded-lg border border-gray-300 px-3 py-2 text-sm text-gray-900 focus:border-indigo-500 focus:outline-none focus:ring-1 focus:ring-indigo-500"
              :class="{ 'border-red-400': errors.origin }"
            />
            <p v-if="errors.origin" class="mt-1 text-sm text-red-600">{{ errors.origin }}</p>
          </div>

          <div>
            <label for="destination" class="block text-sm font-medium text-gray-700">
              Destination
            </label>
            <input
              id="destination"
              v-model="form.destination"
              type="text"
              placeholder="e.g. Austin, TX"
              class="mt-1 block w-full rounded-lg border border-gray-300 px-3 py-2 text-sm text-gray-900 focus:border-indigo-500 focus:outline-none focus:ring-1 focus:ring-indigo-500"
              :class="{ 'border-red-400': errors.destination }"
            />
            <p v-if="errors.destination" class="mt-1 text-sm text-red-600">
              {{ errors.destination }}
            </p>
          </div>

          <div>
            <label for="move_date" class="block text-sm font-medium text-gray-700">
              Move date
            </label>
            <input
              id="move_date"
              v-model="form.move_date"
              type="date"
              class="mt-1 block w-full rounded-lg border border-gray-300 px-3 py-2 text-sm text-gray-900 focus:border-indigo-500 focus:outline-none focus:ring-1 focus:ring-indigo-500"
              :class="{ 'border-red-400': errors.move_date }"
            />
            <p v-if="errors.move_date" class="mt-1 text-sm text-red-600">
              {{ errors.move_date }}
            </p>
          </div>

          <div>
            <label for="notes" class="block text-sm font-medium text-gray-700">
              Notes <span class="text-gray-400">(optional)</span>
            </label>
            <textarea
              id="notes"
              v-model="form.notes"
              rows="3"
              placeholder="Any special instructions..."
              class="mt-1 block w-full rounded-lg border border-gray-300 px-3 py-2 text-sm text-gray-900 focus:border-indigo-500 focus:outline-none focus:ring-1 focus:ring-indigo-500"
            />
          </div>

          <p v-if="submitError" class="text-sm text-red-600">{{ submitError }}</p>

          <div class="mt-2 flex justify-end gap-3">
            <button
              type="button"
              class="rounded-lg border border-gray-300 px-4 py-2 text-sm font-medium text-gray-700 transition hover:bg-gray-50"
              @click="emit('close')"
            >
              Cancel
            </button>
            <button
              type="submit"
              :disabled="submitting"
              class="rounded-lg bg-indigo-600 px-4 py-2 text-sm font-medium text-white transition hover:bg-indigo-500 disabled:cursor-not-allowed disabled:opacity-60"
            >
              {{ submitting ? 'Saving...' : isEditMode ? 'Save Changes' : 'Create Request' }}
            </button>
          </div>
        </form>
      </div>
    </div>
  </Transition>
</template>

<style scoped>
.modal-enter-active,
.modal-leave-active {
  transition: opacity 0.2s ease;
}
.modal-enter-from,
.modal-leave-to {
  opacity: 0;
}
.modal-enter-active .modal-panel,
.modal-leave-active .modal-panel {
  transition:
    transform 0.2s ease,
    opacity 0.2s ease;
}
.modal-enter-from .modal-panel,
.modal-leave-to .modal-panel {
  transform: scale(0.95);
  opacity: 0;
}
</style>
