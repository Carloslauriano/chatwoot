import { ref } from 'vue';

// Shared, module-level state so every mounted TimerWidget instance in this
// browser session can detect when RN01 (single active timer per agent)
// caused a DIFFERENT ticket's timer to become the active one, and react by
// showing the "paused automatically" toast on its own widget.
export const activeTimerTicketId = ref(null);
