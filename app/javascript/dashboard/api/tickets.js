/* global axios */

import ApiClient from './ApiClient';

class TicketsAPI extends ApiClient {
  constructor() {
    super('tickets', { accountScoped: true });
  }

  // teamIds vazio/omitido: retorna todos os tickets da conta.
  // teamIds presente: filtra por team_id[] (usado pelo Kanban).
  list(teamIds = []) {
    const params = teamIds.length ? { team_id: teamIds } : {};
    return axios.get(this.url, { params });
  }

  getByConversation(conversationId) {
    return axios.get(this.url, { params: { conversation_id: conversationId } });
  }

  searchOpenByContact(contactId) {
    return axios.get(this.url, {
      params: { contact_id: contactId, exclude_status: 'resolvido' },
    });
  }

  linkConversation(ticketId, conversationId) {
    return axios.post(`${this.url}/${ticketId}/link_conversation`, {
      conversation_id: conversationId,
    });
  }

  transfer(ticketId, setorDestino) {
    return axios.patch(`${this.url}/${ticketId}/transfer`, {
      setor_destino: setorDestino,
    });
  }

  updateStatusMacro(ticketId, statusMacro) {
    return axios.patch(`${this.url}/${ticketId}/status_macro`, {
      status_macro: statusMacro,
    });
  }

  // Substitui updateStatusMacro — colunas do Kanban agora são configuráveis
  // (TicketStatus), não mais o enum fixo de 5 valores.
  updateTicketStatus(ticketId, ticketStatusId) {
    return axios.patch(`${this.url}/${ticketId}/ticket_status`, {
      ticket_status_id: ticketStatusId,
    });
  }

  // Setor = Time: troca de time do ticket (não é mais um campo de texto livre).
  transferTeam(ticketId, teamId) {
    return axios.patch(`${this.url}/${ticketId}/transfer`, {
      team_id: teamId,
    });
  }

  updateStatusMicro(ticketId, assignmentId, statusMicro) {
    return axios.patch(`${this.url}/${ticketId}/assignments/${assignmentId}`, {
      status_micro: statusMicro,
    });
  }

  addMember(ticketId, colaboradorId) {
    return axios.post(`${this.url}/${ticketId}/assignments`, {
      ticket_assignment: { colaborador_id: colaboradorId },
    });
  }

  removeMember(ticketId, assignmentId) {
    return axios.delete(`${this.url}/${ticketId}/assignments/${assignmentId}`);
  }

  timerStart(ticketId) {
    return axios.post(`${this.url}/${ticketId}/timer/start`);
  }

  timerStop(ticketId, decisao) {
    return axios.post(`${this.url}/${ticketId}/timer/stop`, { decisao });
  }

  createWorklog(ticketId, payload) {
    return axios.post(`${this.url}/${ticketId}/worklogs`, payload);
  }

  updateWorklog(ticketId, worklogId, payload) {
    return axios.patch(
      `${this.url}/${ticketId}/worklogs/${worklogId}`,
      payload
    );
  }

  deleteWorklog(ticketId, worklogId) {
    return axios.delete(`${this.url}/${ticketId}/worklogs/${worklogId}`);
  }

  getTimeline(ticketId) {
    return axios.get(`${this.url}/${ticketId}/timeline`);
  }

  getAuditLogs(ticketId) {
    return axios.get(`${this.url}/${ticketId}/audit_logs`);
  }

  updateLabels(ticketId, labels) {
    return axios.post(`${this.url}/${ticketId}/labels`, { labels });
  }

  archive(ticketId) {
    return axios.patch(`${this.url}/${ticketId}/archive`);
  }

  unarchive(ticketId) {
    return axios.patch(`${this.url}/${ticketId}/unarchive`);
  }
}

export default new TicketsAPI();
