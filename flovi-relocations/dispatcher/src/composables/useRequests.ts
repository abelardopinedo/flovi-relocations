import { onUnmounted, ref } from 'vue'
import type { RealtimeChannel } from '@supabase/supabase-js'
import { supabase } from '../lib/supabase'
import { useAuth } from './useAuth'

export interface RelocationRequest {
  id: string
  origin: string
  destination: string
  move_date: string
  notes: string | null
  status: 'open' | 'booked' | 'completed'
  dispatcher_id: string | null
  driver_id: string | null
  created_at: string
  updated_at: string
}

export interface RequestPayload {
  origin: string
  destination: string
  move_date: string
  notes?: string | null
}

const TABLE = 'relocation_requests'

const requests = ref<RelocationRequest[]>([])
const loading = ref(false)
const error = ref<string | null>(null)

let channel: RealtimeChannel | null = null

function sortByCreatedAtDesc(list: RelocationRequest[]) {
  return [...list].sort(
    (a, b) => new Date(b.created_at).getTime() - new Date(a.created_at).getTime(),
  )
}

function upsertRequest(row: RelocationRequest) {
  const index = requests.value.findIndex((r) => r.id === row.id)
  if (index === -1) {
    requests.value = sortByCreatedAtDesc([...requests.value, row])
  } else {
    const next = [...requests.value]
    next[index] = row
    requests.value = next
  }
  console.log(
    '[useRequests] requests after mutation:',
    requests.value.map((r) => ({ id: r.id, origin: r.origin, status: r.status })),
  )
}

function subscribeToChanges() {
  if (channel) return

  channel = supabase
    .channel('relocation_requests-changes')
    .on(
      'postgres_changes',
      { event: 'INSERT', schema: 'public', table: TABLE },
      (payload) => {
        console.log('[useRequests] realtime INSERT event received:', payload.new)
        upsertRequest(payload.new as RelocationRequest)
      },
    )
    .on(
      'postgres_changes',
      { event: 'UPDATE', schema: 'public', table: TABLE },
      (payload) => {
        console.log('[useRequests] realtime UPDATE event received:', payload.new)
        upsertRequest(payload.new as RelocationRequest)
      },
    )
    .subscribe((status, err) => {
      console.log('[useRequests] realtime channel status:', status, err ?? '')
    })
}

function unsubscribeFromChanges() {
  if (channel) {
    supabase.removeChannel(channel)
    channel = null
  }
}

async function fetchRequests() {
  loading.value = true
  error.value = null

  const { data, error: fetchError } = await supabase
    .from(TABLE)
    .select('*')
    .order('created_at', { ascending: false })

  if (fetchError) {
    error.value = fetchError.message
  } else {
    requests.value = data ?? []
  }

  loading.value = false
}

async function createRequest(payload: RequestPayload) {
  const { user } = useAuth()
  if (!user.value) {
    const message = 'You must be signed in to create a request.'
    error.value = message
    throw new Error(message)
  }

  error.value = null

  const { data, error: insertError } = await supabase
    .from(TABLE)
    .insert({
      origin: payload.origin,
      destination: payload.destination,
      move_date: payload.move_date,
      notes: payload.notes ?? null,
      status: 'open',
      dispatcher_id: user.value.id,
    })
    .select()
    .single()

  if (insertError) {
    error.value = insertError.message
    throw insertError
  }

  console.log('[useRequests] createRequest resolved, applying row directly:', data)
  upsertRequest(data as RelocationRequest)
}

async function updateRequest(id: string, payload: RequestPayload) {
  error.value = null

  const { data, error: updateError } = await supabase
    .from(TABLE)
    .update({
      origin: payload.origin,
      destination: payload.destination,
      move_date: payload.move_date,
      notes: payload.notes ?? null,
      updated_at: new Date().toISOString(),
    })
    .eq('id', id)
    .select()
    .single()

  if (updateError) {
    error.value = updateError.message
    throw updateError
  }

  console.log('[useRequests] updateRequest resolved, applying row directly:', data)
  upsertRequest(data as RelocationRequest)
}

export function useRequests() {
  subscribeToChanges()

  onUnmounted(() => {
    unsubscribeFromChanges()
  })

  return { requests, loading, error, fetchRequests, createRequest, updateRequest }
}
