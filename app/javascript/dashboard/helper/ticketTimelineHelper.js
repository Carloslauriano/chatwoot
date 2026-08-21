import { formatDistanceToNow } from 'date-fns';
import { ptBR } from 'date-fns/locale';
import { formatDuration } from 'shared/helpers/timeHelper';

const STATUS_MACRO_LABELS = {
  caixa_entrada: 'Caixa de Entrada',
  a_fazer: 'A Fazer',
  fazendo: 'Fazendo',
  aguardando_versao: 'Aguardando Versão',
  resolvido: 'Resolvido',
};

const STATUS_MICRO_LABELS = {
  a_fazer: 'A Fazer',
  fazendo: 'Fazendo',
  finalizado: 'Finalizado',
};

// Centraliza a leitura das chaves de payload de cada tipo de evento da
// timeline — os nomes de campo vêm do backend (tickets_controller.rb) e já
// causaram bugs quando o frontend lia uma chave diferente. Mudar isso num só
// lugar evita repetir esse erro.
export const describeTicketEvent = (event, t) => {
  const { tipo_evento: type, payload = {}, autor_nome: autor } = event;
  const agentFallback = t('TICKETS.TIMELINE.EVENTS.AGENT_FALLBACK');

  const map = {
    mensagem_cliente: {
      dot: 'bg-blue-500',
      icon: 'i-lucide-message-circle',
      label:
        payload.incoming === false
          ? t('TICKETS.TIMELINE.EVENTS.AGENT_MESSAGE', {
              agent: autor || agentFallback,
            })
          : t('TICKETS.TIMELINE.EVENTS.CUSTOMER_MESSAGE'),
    },
    nota_interna: {
      dot: 'bg-amber-500',
      icon: 'i-lucide-sticky-note',
      label: t('TICKETS.TIMELINE.EVENTS.INTERNAL_NOTE'),
    },
    status_macro_changed: {
      dot: 'bg-n-slate-6',
      icon: 'i-lucide-shuffle',
      label: t('TICKETS.TIMELINE.EVENTS.STATUS_MACRO_CHANGED', {
        agent: autor || agentFallback,
        from:
          STATUS_MACRO_LABELS[payload.status_macro_antes] ||
          payload.status_macro_antes,
        to:
          STATUS_MACRO_LABELS[payload.status_macro_depois] ||
          payload.status_macro_depois,
      }),
    },
    status_micro_changed: {
      dot: 'bg-n-slate-4',
      icon: 'i-lucide-check',
      label: t('TICKETS.TIMELINE.EVENTS.STATUS_MICRO_CHANGED', {
        agent: autor || agentFallback,
        from:
          STATUS_MICRO_LABELS[payload.status_micro_antes] ||
          payload.status_micro_antes,
        to:
          STATUS_MICRO_LABELS[payload.status_micro_depois] ||
          payload.status_micro_depois,
      }),
    },
    setor_changed: {
      dot: 'bg-purple-500',
      icon: 'i-lucide-corner-up-right',
      label: t('TICKETS.TIMELINE.EVENTS.SECTOR_TRANSFERRED', {
        agent: autor || agentFallback,
        from: payload.setor_origem,
        to: payload.setor_destino,
      }),
    },
    worklog: {
      dot: 'bg-green-500',
      icon: 'i-lucide-clock',
      label: t('TICKETS.TIMELINE.EVENTS.WORKED', {
        agent: autor || agentFallback,
        duration: formatDuration(payload.duracao_segundos),
      }),
    },
    worklog_manual: {
      dot: 'bg-green-500',
      icon: 'i-lucide-clock-3',
      label: t('TICKETS.TIMELINE.EVENTS.WORKED_MANUAL', {
        agent: autor || agentFallback,
        duration: formatDuration(payload.duracao_segundos),
      }),
    },
  };

  return (
    map[type] || {
      dot: 'bg-n-slate-4',
      icon: 'i-lucide-circle',
      label: type,
    }
  );
};

export const ticketEventText = event => event.payload?.texto || '';

// App é pt-BR only (ver _expxagents/_memory/preferences.md) — sem precisar
// resolver o locale do vue-i18n dinamicamente para o date-fns.
export const activityTimeAgo = date =>
  formatDistanceToNow(new Date(date), { addSuffix: true, locale: ptBR });
