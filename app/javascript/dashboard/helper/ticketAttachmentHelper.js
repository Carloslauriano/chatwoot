// Anexos de ticket (Ticket#anexos, TicketTimelineEvent#anexos) só trazem
// id/filename/url/content_type/byte_size — sem o enum file_type que o
// Attachment (mensagem de conversa) tem, então a checagem de imagem aqui é
// por content_type com fallback pra extensão do filename.
const IMAGE_EXTENSION_REGEX = /\.(png|jpe?g|gif|webp|bmp|svg)$/i;

export const isImageAttachment = anexo => {
  if (anexo?.content_type) return anexo.content_type.startsWith('image/');
  return IMAGE_EXTENSION_REGEX.test(anexo?.filename || '');
};
