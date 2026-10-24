import React, { useState, useEffect } from 'react';
import {
  Bell,
  Send,
  Compass,
  Clock,
} from 'lucide-react';
import { PushNotificationPayload, SentNotificationRecord, PbCityItem } from '../types';
import { sendPushNotification } from '../services/api';

interface NotificationsTabProps {
  cities: PbCityItem[];
  selectedUf: string;
  onShowToast: (message: string, type?: 'success' | 'error') => void;
  isAuthenticated: boolean;
  onOpenLogin: () => void;
}

export const NotificationsTab: React.FC<NotificationsTabProps> = ({
  cities,
  selectedUf,
  onShowToast,
  isAuthenticated,
  onOpenLogin,
}) => {
  const [topicType, setTopicType] = useState<'state_general' | 'promotions' | 'events' | 'city' | 'global'>('promotions');
  const [selectedCitySlug, setSelectedCitySlug] = useState<string>('recife');
  const [title, setTitle] = useState('');
  const [body, setBody] = useState('');
  const [imageUrl, setImageUrl] = useState('');
  const [actionType, setActionType] = useState<'open_city' | 'open_attraction' | 'open_url' | 'open_trip'>('open_city');
  const [actionValue, setActionValue] = useState('recife');
  const [isSending, setIsSending] = useState(false);
  const [history, setHistory] = useState<SentNotificationRecord[]>([]);

  // Load history from localStorage
  useEffect(() => {
    try {
      const stored = localStorage.getItem('onetour_push_history');
      if (stored) {
        setHistory(JSON.parse(stored));
      }
    } catch {
      // ignore
    }
  }, []);

  const saveToHistory = (record: SentNotificationRecord) => {
    const updated = [record, ...history].slice(0, 20);
    setHistory(updated);
    try {
      localStorage.setItem('onetour_push_history', JSON.stringify(updated));
    } catch {
      // ignore
    }
  };

  // Determine effective topic string
  const getEffectiveTopic = (): string => {
    const uf = selectedUf.toLowerCase();
    switch (topicType) {
      case 'state_general':
        return `${uf}_geral`;
      case 'promotions':
        return `${uf}_promocoes`;
      case 'events':
        return `${uf}_eventos`;
      case 'city':
        return `${uf}_${selectedCitySlug.replace(/-/g, '_')}`;
      case 'global':
        return 'global_ofertas';
      default:
        return `${uf}_promocoes`;
    }
  };

  const handleSend = async (e: React.FormEvent) => {
    e.preventDefault();

    if (!isAuthenticated) {
      onOpenLogin();
      onShowToast('Autentique-se como administrador para disparar notificações.', 'error');
      return;
    }

    if (!title.trim() || !body.trim()) {
      onShowToast('Preencha o título e o corpo da mensagem.', 'error');
      return;
    }

    setIsSending(true);
    const targetTopic = getEffectiveTopic();

    try {
      const payload: PushNotificationPayload = {
        topic: targetTopic,
        title: title.trim(),
        body: body.trim(),
        image_url: imageUrl.trim() || undefined,
        action_type: actionType,
        action_value: actionValue.trim() || undefined,
      };

      const res = await sendPushNotification(payload);

      const record: SentNotificationRecord = {
        id: res.message_id || `notif_${Date.now()}`,
        topic: targetTopic,
        title: payload.title,
        body: payload.body,
        image_url: payload.image_url,
        action_type: payload.action_type || 'open_city',
        action_value: payload.action_value || '',
        sent_at: new Date().toISOString(),
      };

      saveToHistory(record);
      onShowToast(`Push disparado com sucesso para o tópico /topics/${targetTopic}!`);

      // Reset form
      setTitle('');
      setBody('');
      setImageUrl('');
    } catch (err: any) {
      onShowToast(`Erro ao disparar push: ${err.message}`, 'error');
    } finally {
      setIsSending(false);
    }
  };

  const fillTemplate = (type: 'mare' | 'carnaval' | 'desconto') => {
    if (type === 'mare') {
      setTitle('🌊 Maré Baixa em Porto de Galinhas!');
      setBody('A maré estará em 0.1m às 10h40 hoje. Horário perfeito para passeio de jangada nas piscinas naturais.');
      setImageUrl('https://images.unsplash.com/photo-1507525428034-b723cf961d3e?auto=format&fit=crop&w=800&q=80');
      setActionType('open_city');
      setActionValue('porto_de_galinhas');
      setTopicType('city');
      setSelectedCitySlug('porto_de_galinhas');
    } else if (type === 'carnaval') {
      setTitle('🎭 Galo da Madrugada e Olinda Histórica!');
      setBody('Confira a programação de blocos e os melhores pontos de apoio para curtir o maior carnaval do mundo.');
      setImageUrl('https://images.unsplash.com/photo-1544620347-c4fd4a3d5957?auto=format&fit=crop&w=800&q=80');
      setActionType('open_city');
      setActionValue('recife');
      setTopicType('events');
    } else {
      setTitle('🏷️ 20% OFF no Passeio de Catamarã');
      setBody('Passeio pelas pontes do Recife com desconto exclusivo para usuários do app Tour Pernambuco.');
      setImageUrl('https://images.unsplash.com/photo-1569263979104-865ab7cd8d17?auto=format&fit=crop&w=800&q=80');
      setActionType('open_url');
      setActionValue('https://catamarantours.com.br?ref=onetour_pe');
      setTopicType('promotions');
    }
  };

  const effectiveTopic = getEffectiveTopic();

  return (
    <div style={{ display: 'flex', flexDirection: 'column', gap: 24 }}>
      {/* Header Panel */}
      <div
        className="glass-panel"
        style={{
          padding: '24px 28px',
          display: 'flex',
          justifyContent: 'space-between',
          alignItems: 'center',
          flexWrap: 'wrap',
          gap: 16,
        }}
      >
        <div>
          <div style={{ display: 'flex', alignItems: 'center', gap: 10, marginBottom: 6 }}>
            <span className="badge badge-primary">FIREBASE CLOUD MESSAGING</span>
            <span style={{ fontSize: '0.8rem', color: 'var(--text-muted)' }}>
              Disparador Central de Campanhas Push
            </span>
          </div>
          <h1 style={{ fontSize: '1.5rem', fontWeight: 700 }}>
            Push Notifications Segmentadas por Estado e Cidade
          </h1>
          <p style={{ fontSize: '0.875rem', color: 'var(--text-muted)', marginTop: 4 }}>
            Envie alertas em tempo real para os celulares dos turistas inscritos nos tópicos do Tour Pernambuco.
          </p>
        </div>

        <div style={{ display: 'flex', alignItems: 'center', gap: 10 }}>
          <span style={{ fontSize: '0.85rem', color: 'var(--text-muted)' }}>Sugestões rápidas:</span>
          <button
            type="button"
            onClick={() => fillTemplate('mare')}
            className="btn btn-secondary"
            style={{ fontSize: '0.75rem', padding: '6px 12px' }}
          >
            🌊 Maré Baixa
          </button>
          <button
            type="button"
            onClick={() => fillTemplate('desconto')}
            className="btn btn-secondary"
            style={{ fontSize: '0.75rem', padding: '6px 12px' }}
          >
            🏷️ Cupom Parceiro
          </button>
          <button
            type="button"
            onClick={() => fillTemplate('carnaval')}
            className="btn btn-secondary"
            style={{ fontSize: '0.75rem', padding: '6px 12px' }}
          >
            🎭 Eventos / Folia
          </button>
        </div>
      </div>

      {/* Main Grid: Form + Live Smartphone Preview */}
      <div
        style={{
          display: 'grid',
          gridTemplateColumns: 'repeat(auto-fit, minmax(360px, 1fr))',
          gap: 24,
          alignItems: 'start',
        }}
      >
        {/* Left Column: Form */}
        <div className="glass-panel" style={{ padding: 24 }}>
          <h2 style={{ fontSize: '1.15rem', fontWeight: 700, marginBottom: 18, display: 'flex', alignItems: 'center', gap: 8 }}>
            <Bell size={18} color="var(--primary)" />
            <span>Configurar Disparo Push</span>
          </h2>

          <form onSubmit={handleSend} style={{ display: 'flex', flexDirection: 'column', gap: 16 }}>
            {/* Topic Target Selector */}
            <div>
              <label style={{ display: 'block', fontSize: '0.825rem', fontWeight: 600, color: 'var(--text-muted)', marginBottom: 8 }}>
                Público-Alvo e Segmentação por Tópico
              </label>
              <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 8 }}>
                <button
                  type="button"
                  onClick={() => setTopicType('promotions')}
                  className={`btn ${topicType === 'promotions' ? 'btn-primary' : 'btn-secondary'}`}
                  style={{ fontSize: '0.8rem', padding: '8px' }}
                >
                  🏷️ Promoções ({selectedUf})
                </button>
                <button
                  type="button"
                  onClick={() => setTopicType('events')}
                  className={`btn ${topicType === 'events' ? 'btn-primary' : 'btn-secondary'}`}
                  style={{ fontSize: '0.8rem', padding: '8px' }}
                >
                  🎉 Eventos & Cultura
                </button>
                <button
                  type="button"
                  onClick={() => setTopicType('state_general')}
                  className={`btn ${topicType === 'state_general' ? 'btn-primary' : 'btn-secondary'}`}
                  style={{ fontSize: '0.8rem', padding: '8px' }}
                >
                  📢 Geral ({selectedUf})
                </button>
                <button
                  type="button"
                  onClick={() => setTopicType('city')}
                  className={`btn ${topicType === 'city' ? 'btn-primary' : 'btn-secondary'}`}
                  style={{ fontSize: '0.8rem', padding: '8px' }}
                >
                  📍 Por Cidade
                </button>
              </div>

              {topicType === 'city' && (
                <div style={{ marginTop: 10 }}>
                  <select
                    className="select-field"
                    value={selectedCitySlug}
                    onChange={(e) => setSelectedCitySlug(e.target.value)}
                    style={{ width: '100%' }}
                  >
                    {cities.map((c) => (
                      <option key={c.slug} value={c.slug}>
                        {c.nome} ({selectedUf})
                      </option>
                    ))}
                    <option value="porto_de_galinhas">Porto de Galinhas</option>
                    <option value="recife">Recife</option>
                    <option value="olinda">Olinda</option>
                    <option value="carneiros">Praia dos Carneiros</option>
                    <option value="noronha">Fernando de Noronha</option>
                  </select>
                </div>
              )}

              <div style={{ marginTop: 8, fontSize: '0.78rem', color: 'var(--accent-cyan)' }}>
                Tópico FCM de destino: <code>/topics/{effectiveTopic}</code>
              </div>
            </div>

            {/* Notification Title */}
            <div>
              <label style={{ display: 'block', fontSize: '0.825rem', fontWeight: 600, color: 'var(--text-muted)', marginBottom: 6 }}>
                Título da Mensagem *
              </label>
              <input
                type="text"
                required
                className="input-field"
                placeholder="Ex: Maré Baixa em Carneiros!"
                value={title}
                onChange={(e) => setTitle(e.target.value)}
                maxLength={65}
              />
              <span style={{ fontSize: '0.72rem', color: 'var(--text-dim)', float: 'right', marginTop: 2 }}>
                {title.length}/65
              </span>
            </div>

            {/* Notification Body */}
            <div>
              <label style={{ display: 'block', fontSize: '0.825rem', fontWeight: 600, color: 'var(--text-muted)', marginBottom: 6 }}>
                Corpo da Notificação *
              </label>
              <textarea
                required
                className="input-field"
                rows={3}
                placeholder="Ex: As piscinas naturais estão no auge agora às 11h. Aproveite o passeio de jangada!"
                value={body}
                onChange={(e) => setBody(e.target.value)}
                maxLength={180}
                style={{ resize: 'vertical' }}
              />
              <span style={{ fontSize: '0.72rem', color: 'var(--text-dim)', float: 'right', marginTop: 2 }}>
                {body.length}/180
              </span>
            </div>

            {/* Rich Image URL */}
            <div>
              <label style={{ display: 'block', fontSize: '0.825rem', fontWeight: 600, color: 'var(--text-muted)', marginBottom: 6 }}>
                URL da Imagem de Capa (Rich Push, opcional)
              </label>
              <input
                type="url"
                className="input-field"
                placeholder="https://exemplo.com/foto-alta-resolucao.jpg"
                value={imageUrl}
                onChange={(e) => setImageUrl(e.target.value)}
              />
            </div>

            {/* Deep Linking Action */}
            <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 12 }}>
              <div>
                <label style={{ display: 'block', fontSize: '0.825rem', fontWeight: 600, color: 'var(--text-muted)', marginBottom: 6 }}>
                  Ação ao Tocar
                </label>
                <select
                  className="select-field"
                  value={actionType}
                  onChange={(e) => setActionType(e.target.value as any)}
                  style={{ width: '100%' }}
                >
                  <option value="open_city">Abrir Cidade</option>
                  <option value="open_attraction">Abrir Atração</option>
                  <option value="open_trip">Abrir Roteiro</option>
                  <option value="open_url">Link / Cupom Externo</option>
                </select>
              </div>

              <div>
                <label style={{ display: 'block', fontSize: '0.825rem', fontWeight: 600, color: 'var(--text-muted)', marginBottom: 6 }}>
                  Parâmetro da Ação
                </label>
                <input
                  type="text"
                  className="input-field"
                  placeholder="Slug ou URL"
                  value={actionValue}
                  onChange={(e) => setActionValue(e.target.value)}
                />
              </div>
            </div>

            {/* Submit Button */}
            <button
              type="submit"
              disabled={isSending}
              className="btn btn-primary"
              style={{ width: '100%', padding: '12px 18px', marginTop: 10, fontSize: '0.95rem' }}
            >
              <Send size={16} />
              <span>{isSending ? 'Disparando Notificação...' : `Disparar para /topics/${effectiveTopic}`}</span>
            </button>
          </form>
        </div>

        {/* Right Column: Smartphone Live Preview */}
        <div style={{ display: 'flex', flexDirection: 'column', gap: 18, alignItems: 'center' }}>
          <div style={{ fontSize: '0.85rem', fontWeight: 600, color: 'var(--text-muted)' }}>
            Pré-visualização no Smartphone do Turista
          </div>

          {/* Phone Frame */}
          <div
            style={{
              width: 320,
              borderRadius: 36,
              background: '#0a0f1d',
              border: '4px solid #1e293b',
              boxShadow: '0 20px 40px rgba(0, 0, 0, 0.7), 0 0 30px rgba(99, 102, 241, 0.2)',
              overflow: 'hidden',
              display: 'flex',
              flexDirection: 'column',
              padding: '16px 14px',
              minHeight: 460,
              position: 'relative',
            }}
          >
            {/* Notch */}
            <div
              style={{
                width: 100,
                height: 18,
                background: '#1e293b',
                borderRadius: '0 0 12px 12px',
                margin: '-16px auto 14px auto',
              }}
            />

            {/* Lockscreen Header Clock */}
            <div style={{ textAlign: 'center', marginBottom: 20 }}>
              <div style={{ fontSize: '2.4rem', fontWeight: 800, color: '#f8fafc', lineHeight: 1 }}>
                09:41
              </div>
              <div style={{ fontSize: '0.75rem', color: '#94a3b8', marginTop: 4 }}>
                Sexta-feira, 24 de Outubro
              </div>
            </div>

            {/* Live Notification Card */}
            <div
              style={{
                background: 'rgba(30, 41, 59, 0.85)',
                backdropFilter: 'blur(16px)',
                borderRadius: 16,
                padding: 14,
                border: '1px solid rgba(255, 255, 255, 0.12)',
                boxShadow: '0 8px 20px rgba(0, 0, 0, 0.4)',
              }}
            >
              {/* App Icon + App Name */}
              <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: 8 }}>
                <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
                  <div
                    style={{
                      width: 20,
                      height: 20,
                      borderRadius: 5,
                      background: 'var(--primary-gradient)',
                      display: 'flex',
                      alignItems: 'center',
                      justifyContent: 'center',
                    }}
                  >
                    <Compass size={12} color="white" />
                  </div>
                  <span style={{ fontSize: '0.75rem', fontWeight: 700, color: '#f8fafc' }}>
                    TOUR PERNAMBUCO
                  </span>
                </div>
                <span style={{ fontSize: '0.65rem', color: '#94a3b8' }}>agora</span>
              </div>

              {/* Title & Body */}
              <div style={{ fontWeight: 700, fontSize: '0.85rem', color: '#f8fafc', marginBottom: 4 }}>
                {title || 'Título da Notificação Push'}
              </div>
              <div style={{ fontSize: '0.78rem', color: '#cbd5e1', lineHeight: 1.4 }}>
                {body || 'Corpo da mensagem com detalhes da atração, maré ou oferta especial...'}
              </div>

              {/* Image Preview if provided */}
              {imageUrl && (
                <div
                  style={{
                    marginTop: 10,
                    borderRadius: 10,
                    overflow: 'hidden',
                    height: 120,
                    background: '#151d2f',
                  }}
                >
                  <img
                    src={imageUrl}
                    alt="Push Preview"
                    style={{ width: '100%', height: '100%', objectFit: 'cover' }}
                    onError={(e) => {
                      (e.target as any).style.display = 'none';
                    }}
                  />
                </div>
              )}
            </div>

            {/* Bottom Indicator */}
            <div
              style={{
                marginTop: 'auto',
                width: 110,
                height: 4,
                background: '#475569',
                borderRadius: 2,
                alignSelf: 'center',
              }}
            />
          </div>
        </div>
      </div>

      {/* History of Dispatches */}
      <div className="glass-panel" style={{ padding: 22 }}>
        <h3 style={{ fontSize: '1rem', fontWeight: 700, marginBottom: 14, display: 'flex', alignItems: 'center', gap: 8 }}>
          <Clock size={16} color="var(--accent-cyan)" />
          <span>Histórico de Notificações Disparadas Recentemente</span>
        </h3>

        {history.length === 0 ? (
          <div style={{ textAlign: 'center', padding: '24px 16px', color: 'var(--text-muted)', fontSize: '0.85rem' }}>
            Nenhuma notificação disparada nesta sessão ainda.
          </div>
        ) : (
          <div style={{ display: 'flex', flexDirection: 'column', gap: 10 }}>
            {history.map((item) => (
              <div
                key={item.id}
                style={{
                  display: 'flex',
                  alignItems: 'center',
                  justifyContent: 'space-between',
                  padding: '12px 16px',
                  borderRadius: 'var(--radius-sm)',
                  background: 'rgba(255, 255, 255, 0.03)',
                  border: '1px solid var(--border-subtle)',
                  flexWrap: 'wrap',
                  gap: 12,
                }}
              >
                <div>
                  <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
                    <span className="badge badge-primary">{item.topic}</span>
                    <span style={{ fontWeight: 700, fontSize: '0.9rem' }}>{item.title}</span>
                  </div>
                  <div style={{ fontSize: '0.8rem', color: 'var(--text-muted)', marginTop: 4 }}>
                    {item.body}
                  </div>
                </div>

                <div style={{ fontSize: '0.75rem', color: 'var(--text-dim)' }}>
                  {new Date(item.sent_at).toLocaleTimeString('pt-BR', { hour: '2-digit', minute: '2-digit' })}
                </div>
              </div>
            ))}
          </div>
        )}
      </div>
    </div>
  );
};
