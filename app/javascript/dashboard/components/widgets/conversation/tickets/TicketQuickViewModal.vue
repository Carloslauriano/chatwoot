<script setup>
import { ref, onMounted, watch } from 'vue';
import { useI18n } from 'vue-i18n';
import { useRouter } from 'vue-router';
import TicketsAPI from 'dashboard/api/tickets';
import { useAccount } from 'dashboard/composables/useAccount';
import { useAlert } from 'dashboard/composables';
import { useMessageFormatter } from 'shared/composables/useMessageFormatter';
import { useLinkPreviewEnrichment } from 'dashboard/composables/useLinkPreviewEnrichment';
import Spinner from 'dashboard/components-next/spinner/Spinner.vue';
import Button from 'dashboard/components-next/button/Button.vue';
import Avatar from 'dashboard/components-next/avatar/Avatar.vue';
import WootMessageEditor from 'dashboard/components/widgets/WootWriter/Editor.vue';
import {
  describeTicketEvent,
  ticketEventText,
  activityTimeAgo,
} from 'dashboard/helper/ticketTimelineHelper';
import TicketHeaderCard from './TicketHeaderCard.vue';

const props = defineProps({
  ticketId: {
    type: [Number, String],
    required: true,
  },
});

const emit = defineEmits(['updated']);
const { t } = useI18n();
const router = useRouter();
const { accountId } = useAccount();
const { formatMessage } = useMessageFormatter();

const ticket = ref(null);
const isLoading = ref(false);
const events = ref([]);
const isLoadingActivity = ref(false);
const commentDraft = ref('');
const isSavingComment = ref(false);
const commentAttachments = ref([]);
const commentAttachmentInput = ref(null);
const { enrichLinks } = useLinkPreviewEnrichment();
const commentRefs = {};
const setCommentRef = (eventId, el) => {
  if (el) commentRefs[eventId] = el;
};
const enrichCommentLinks = () => {
  Object.values(commentRefs).forEach(enrichLinks);
};

const loadTicket = async () => {
  isLoading.value = true;
  try {
    const response = await TicketsAPI.show(props.ticketId);
    ticket.value = response.data;
  } catch (error) {
    ticket.value = null;
  } finally {
    isLoading.value = false;
  }
};

const loadActivity = async () => {
  isLoadingActivity.value = true;
  try {
    const response = await TicketsAPI.getTimeline(props.ticketId);
    events.value = response.data || [];
    enrichCommentLinks();
  } catch (error) {
    events.value = [];
  } finally {
    isLoadingActivity.value = false;
  }
};

const onUpdated = () => {
  loadTicket();
  emit('updated');
};

const openCommentAttachmentBrowser = () =>
  commentAttachmentInput.value?.click();

const onCommentAttachmentSelected = event => {
  const files = Array.from(event.target.files || []);
  event.target.value = '';
  commentAttachments.value = [...commentAttachments.value, ...files];
};

const removeCommentAttachment = index => {
  commentAttachments.value = commentAttachments.value.filter(
    (_file, fileIndex) => fileIndex !== index
  );
};

const submitComment = async () => {
  if (!commentDraft.value.trim()) return;
  try {
    isSavingComment.value = true;
    await TicketsAPI.createComment(
      props.ticketId,
      commentDraft.value.trim(),
      commentAttachments.value
    );
    commentDraft.value = '';
    commentAttachments.value = [];
    await loadActivity();
  } catch (error) {
    useAlert(t('TICKETS.QUICK_VIEW.COMMENT_ERROR'));
  } finally {
    isSavingComment.value = false;
  }
};

const openConversation = () => {
  if (!ticket.value) return;
  router.push({
    name: 'inbox_conversation',
    params: {
      accountId: accountId.value,
      conversation_id: ticket.value.conversation_id,
    },
  });
};

watch(
  () => props.ticketId,
  () => {
    loadTicket();
    loadActivity();
  }
);

onMounted(() => {
  loadTicket();
  loadActivity();
});
</script>

<template>
  <div class="flex flex-col h-auto overflow-auto">
    <div class="flex flex-col gap-6 px-8 pt-8 pb-6 lg:flex-row">
      <div v-if="isLoading" class="flex justify-center flex-1 p-8">
        <Spinner />
      </div>
      <template v-else-if="ticket">
        <div class="flex-1 min-w-0">
          <TicketHeaderCard :ticket="ticket" @updated="onUpdated" />
        </div>

        <div class="flex flex-col flex-shrink-0 gap-3 lg:w-80">
          <span class="text-xs font-medium text-n-slate-11">
            {{ t('TICKETS.QUICK_VIEW.ACTIVITY') }}
          </span>
          <div class="flex flex-col gap-2">
            <WootMessageEditor
              v-model="commentDraft"
              channel-type="Context::TicketRichText"
              :enable-canned-responses="false"
              :placeholder="t('TICKETS.QUICK_VIEW.COMMENT_PLACEHOLDER')"
            />
            <div v-if="commentAttachments.length" class="flex flex-wrap gap-1">
              <span
                v-for="(file, index) in commentAttachments"
                :key="`${file.name}-${index}`"
                class="flex items-center gap-1 px-2 py-1 text-xs rounded-lg border border-n-weak text-n-slate-11"
              >
                <span class="i-lucide-paperclip size-3 shrink-0" />
                <span class="truncate max-w-[8rem]">{{ file.name }}</span>
                <button
                  type="button"
                  class="hover:text-n-ruby-9"
                  :title="t('TICKETS.QUICK_VIEW.ATTACHMENT_REMOVE')"
                  @click="removeCommentAttachment(index)"
                >
                  <span class="text-[10px] i-lucide-x" />
                </button>
              </span>
            </div>
            <input
              ref="commentAttachmentInput"
              type="file"
              multiple
              class="hidden"
              @change="onCommentAttachmentSelected"
            />
            <div class="flex items-center justify-between gap-2">
              <button
                type="button"
                class="text-xs text-n-slate-11 hover:underline"
                @click="openCommentAttachmentBrowser"
              >
                {{ t('TICKETS.QUICK_VIEW.ATTACH_FILE') }}
              </button>
              <Button
                size="small"
                :label="t('TICKETS.QUICK_VIEW.SEND_COMMENT')"
                :is-loading="isSavingComment"
                :disabled="!commentDraft.trim()"
                @click="submitComment"
              />
            </div>
          </div>
          <div v-if="isLoadingActivity" class="flex justify-center p-4">
            <Spinner />
          </div>
          <p v-else-if="!events.length" class="text-xs text-n-slate-11">
            {{ t('TICKETS.TIMELINE.EMPTY') }}
          </p>
          <ul v-else class="flex flex-col gap-3 overflow-y-auto max-h-[32rem]">
            <li
              v-for="(event, index) in events"
              :key="event.id"
              class="flex gap-2 text-xs"
            >
              <template v-if="index === events.length - 1">
                <span
                  class="flex items-center justify-center w-6 h-6 text-white rounded-full shrink-0 bg-n-slate-8"
                >
                  <span class="text-[11px] i-lucide-flag" />
                </span>
                <div v-if="ticket.conversation_id" class="flex flex-col gap-1">
                  <span class="text-n-slate-12">
                    {{
                      t('TICKETS.TIMELINE.ORIGIN.FROM_CONVERSATION', {
                        id: ticket.conversation_id,
                      })
                    }}
                  </span>
                  <Button
                    size="small"
                    faded
                    slate
                    icon="i-lucide-message-square"
                    :label="t('TICKETS.SHOW.OPEN_CONVERSATION')"
                    class="w-fit"
                    @click="openConversation"
                  />
                </div>
                <div v-else class="flex flex-col gap-1">
                  <span class="text-n-slate-12">
                    {{ t('TICKETS.TIMELINE.ORIGIN.CREATED_STANDALONE') }}
                  </span>
                </div>
              </template>
              <template v-else>
                <Avatar
                  v-if="event.autor_nome"
                  :src="event.autor_avatar_url"
                  :name="event.autor_nome"
                  :size="24"
                  rounded-full
                  class="shrink-0"
                />
                <span
                  v-else
                  class="flex items-center justify-center w-6 h-6 text-white rounded-full shrink-0"
                  :class="describeTicketEvent(event, t).dot"
                >
                  <span
                    :class="describeTicketEvent(event, t).icon"
                    class="text-[11px]"
                  />
                </span>
                <div class="flex flex-col gap-0.5">
                  <span class="text-n-slate-12">
                    {{ describeTicketEvent(event, t).label }}
                  </span>
                  <template v-if="event.tipo_evento === 'comentario'">
                    <div
                      :ref="el => setCommentRef(event.id, el)"
                      v-dompurify-html="formatMessage(event.payload.texto)"
                      class="text-sm break-words text-n-slate-12"
                    />
                    <div
                      v-if="event.anexos?.length"
                      class="flex flex-wrap gap-1"
                    >
                      <a
                        v-for="anexo in event.anexos"
                        :key="anexo.id"
                        :href="anexo.url"
                        target="_blank"
                        rel="noopener noreferrer"
                        class="flex items-center gap-1 px-2 py-1 text-xs rounded-lg border border-n-weak text-n-slate-11 hover:text-n-slate-12"
                      >
                        <span class="i-lucide-paperclip size-3 shrink-0" />
                        <span class="truncate max-w-[8rem]">{{
                          anexo.filename
                        }}</span>
                      </a>
                    </div>
                  </template>
                  <span
                    v-else-if="ticketEventText(event)"
                    class="text-n-slate-11"
                  >
                    {{ ticketEventText(event) }}
                  </span>
                  <span class="text-n-slate-10">
                    {{ activityTimeAgo(event.created_at) }}
                  </span>
                </div>
              </template>
            </li>
          </ul>
        </div>
      </template>
    </div>
  </div>
</template>
