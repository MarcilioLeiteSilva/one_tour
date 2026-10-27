import React, { useState, useEffect } from 'react';
import { X, Layers, MessageCircle, AlertCircle, Check, UploadCloud, Link as LinkIcon, Loader2 } from 'lucide-react';
import { HouseAdCampaign } from '../types';
import { uploadAdImage } from '../services/api';

interface CampaignModalProps {
  isOpen: boolean;
  onClose: () => void;
  onSave: (campaign: Partial<HouseAdCampaign>) => Promise<void>;
  campaignToEdit?: HouseAdCampaign | null;
  defaultUf?: string;
}

export const CampaignModal: React.FC<CampaignModalProps> = ({
  isOpen,
  onClose,
  onSave,
  campaignToEdit,
  defaultUf = 'PE',
}) => {
  const [formData, setFormData] = useState<Partial<HouseAdCampaign>>({
    id: '',
    type: 'direct_sponsor',
    title: '',
    subtitle: '',
    tag: 'RECOMENDADO',
    image_url: '',
    action_label: 'Reservar Agora',
    target_url: '',
    target_uf: defaultUf,
    target_cities: [],
    position: 'home_card',
    priority: 15,
    active: true,
  });

  const [citiesInput, setCitiesInput] = useState<string>('');
  const [whatsAppPhone, setWhatsAppPhone] = useState<string>('');
  const [whatsAppText, setWhatsAppText] = useState<string>('Olá, vi seu anúncio no app One Tour e gostaria de mais informações!');
  const [showWhatsAppHelper, setShowWhatsAppHelper] = useState<boolean>(false);
  const [isSubmitting, setIsSubmitting] = useState<boolean>(false);
  const [error, setError] = useState<string | null>(null);

  // Upload de Mídia
  const [imageInputMode, setImageInputMode] = useState<'upload' | 'url'>('upload');
  const [isUploading, setIsUploading] = useState<boolean>(false);
  const [uploadSuccess, setUploadSuccess] = useState<string | null>(null);

  useEffect(() => {
    if (campaignToEdit) {
      setFormData({
        ...campaignToEdit,
      });
      setCitiesInput(campaignToEdit.target_cities ? campaignToEdit.target_cities.join(', ') : '');
    } else {
      const generatedId = `sponsor_${Date.now().toString(36)}`;
      setFormData({
        id: generatedId,
        type: 'direct_sponsor',
        title: '',
        subtitle: '',
        tag: 'PATROCINADO',
        image_url: 'https://images.unsplash.com/photo-1544620347-c4fd4a3d5957?auto=format&fit=crop&w=800&q=80',
        action_label: 'Reservar com Desconto',
        target_url: '',
        target_uf: defaultUf,
        target_cities: [],
        position: 'home_card',
        priority: 20,
        active: true,
      });
      setCitiesInput('');
    }
    setError(null);
  }, [campaignToEdit, defaultUf, isOpen]);

  if (!isOpen) return null;

  const handleApplyWhatsAppLink = () => {
    const cleanPhone = whatsAppPhone.replace(/\D/g, '');
    if (!cleanPhone) {
      setError('Por favor, informe o número com DDD (ex: 81999998888)');
      return;
    }
    const fullPhone = cleanPhone.startsWith('55') ? cleanPhone : `55${cleanPhone}`;
    const generatedUrl = `https://wa.me/${fullPhone}?text=${encodeURIComponent(whatsAppText)}`;
    setFormData((prev) => ({ ...prev, target_url: generatedUrl }));
    setShowWhatsAppHelper(false);
  };

  const handleFileUpload = async (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0];
    if (!file) return;

    if (file.size > 8 * 1024 * 1024) {
      setError('O arquivo de imagem deve ter no máximo 8MB.');
      return;
    }

    setIsUploading(true);
    setError(null);
    setUploadSuccess(null);

    try {
      const res = await uploadAdImage(file);
      setFormData((prev) => ({ ...prev, image_url: res.url }));
      setUploadSuccess(`Imagem "${file.name}" enviada e salva com sucesso no servidor!`);
    } catch (err: any) {
      setError(err.message || 'Erro ao enviar imagem do anúncio.');
    } finally {
      setIsUploading(false);
    }
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setError(null);

    if (!formData.title?.trim()) {
      setError('O título da campanha é obrigatório.');
      return;
    }
    if (!formData.image_url?.trim()) {
      setError('A URL da imagem é obrigatória.');
      return;
    }
    if (!formData.target_url?.trim()) {
      setError('O link de destino é obrigatório.');
      return;
    }

    const parsedCities = citiesInput
      .split(',')
      .map((c) => c.trim().toLowerCase())
      .filter((c) => c.length > 0);

    setIsSubmitting(true);
    try {
      await onSave({
        ...formData,
        target_cities: parsedCities,
        target_uf: formData.target_uf?.toUpperCase(),
      });
      onClose();
    } catch (err: any) {
      setError(err.message || 'Erro ao salvar campanha.');
    } finally {
      setIsSubmitting(false);
    }
  };

  return (
    <div
      style={{
        position: 'fixed',
        inset: 0,
        zIndex: 1000,
        display: 'flex',
        alignItems: 'center',
        justifyContent: 'center',
        background: 'rgba(0, 0, 0, 0.8)',
        backdropFilter: 'blur(8px)',
        padding: 16,
        overflowY: 'auto',
      }}
    >
      <div
        className="glass-panel animate-fade-in"
        style={{
          width: '100%',
          maxWidth: 780,
          maxHeight: '92vh',
          display: 'flex',
          flexDirection: 'column',
          background: '#0d1322',
          border: '1px solid rgba(255, 255, 255, 0.15)',
          borderRadius: 'var(--radius-lg)',
          boxShadow: 'var(--shadow-glow)',
          overflow: 'hidden',
        }}
      >
        {/* Modal Header */}
        <div
          style={{
            padding: '18px 24px',
            borderBottom: '1px solid var(--border-subtle)',
            display: 'flex',
            alignItems: 'center',
            justifyContent: 'space-between',
            background: 'rgba(255, 255, 255, 0.02)',
          }}
        >
          <div style={{ display: 'flex', alignItems: 'center', gap: 10 }}>
            <div
              style={{
                width: 36,
                height: 36,
                borderRadius: 'var(--radius-sm)',
                background: 'rgba(99, 102, 241, 0.15)',
                display: 'flex',
                alignItems: 'center',
                justifyContent: 'center',
                color: 'var(--primary)',
              }}
            >
              <Layers size={18} />
            </div>
            <div>
              <h2 style={{ fontSize: '1.15rem', fontWeight: 800 }}>
                {campaignToEdit ? 'Editar Campanha House Ads' : 'Nova Campanha • Patrocinador ou Rede'}
              </h2>
              <p style={{ fontSize: '0.75rem', color: 'var(--text-muted)' }}>
                Configure a mídia, posicionamento, regras de alternância e link de conversão.
              </p>
            </div>
          </div>
          <button
            onClick={onClose}
            className="btn btn-secondary"
            style={{ padding: 6, borderRadius: 'var(--radius-sm)' }}
          >
            <X size={18} />
          </button>
        </div>

        {/* Modal Body */}
        <form onSubmit={handleSubmit} style={{ overflowY: 'auto', padding: 24, display: 'flex', flexDirection: 'column', gap: 20 }}>
          {error && (
            <div
              style={{
                padding: '12px 16px',
                borderRadius: 'var(--radius-sm)',
                background: 'rgba(244, 63, 94, 0.15)',
                border: '1px solid rgba(244, 63, 94, 0.3)',
                color: '#fda4af',
                fontSize: '0.825rem',
                display: 'flex',
                alignItems: 'center',
                gap: 8,
              }}
            >
              <AlertCircle size={16} />
              <span>{error}</span>
            </div>
          )}

          {/* Grid: Informações Principais */}
          <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(220px, 1fr))', gap: 16 }}>
            <div>
              <label style={{ fontSize: '0.75rem', fontWeight: 700, color: 'var(--text-muted)', marginBottom: 6, display: 'block' }}>
                ID Único do Anúncio (Slug) *
              </label>
              <input
                type="text"
                className="input-control"
                value={formData.id}
                onChange={(e) => setFormData({ ...formData, id: e.target.value })}
                placeholder="ex: sponsor_pousada_porto"
                required
              />
            </div>

            <div>
              <label style={{ fontSize: '0.75rem', fontWeight: 700, color: 'var(--text-muted)', marginBottom: 6, display: 'block' }}>
                Tipo de Campanha *
              </label>
              <select
                className="input-control"
                value={formData.type}
                onChange={(e) => setFormData({ ...formData, type: e.target.value as any })}
              >
                <option value="direct_sponsor">Patrocinador Local Direto (Venda R$)</option>
                <option value="cross_promotion">Promoção Cruzada da Rede One Tour</option>
              </select>
            </div>

            <div>
              <label style={{ fontSize: '0.75rem', fontWeight: 700, color: 'var(--text-muted)', marginBottom: 6, display: 'block' }}>
                Posição no App *
              </label>
              <select
                className="input-control"
                value={formData.position}
                onChange={(e) => setFormData({ ...formData, position: e.target.value as any })}
              >
                <option value="home_card">Top Card da Cidade (16:9 • Alta Visibilidade)</option>
                <option value="attraction_banner">Banner In-Feed (3:1 • Intercalado no feed)</option>
                <option value="itinerary_footer">Banner de Rodapé (Timeline do Roteiro)</option>
                <option value="interstitial">Intersticial Suave (9:16 Vertical ao gerar roteiro)</option>
              </select>
            </div>
          </div>

          {/* Título, Subtítulo e Tag */}
          <div style={{ display: 'grid', gridTemplateColumns: '2fr 1fr', gap: 16 }}>
            <div>
              <label style={{ fontSize: '0.75rem', fontWeight: 700, color: 'var(--text-muted)', marginBottom: 6, display: 'block' }}>
                Título Principal da Campanha *
              </label>
              <input
                type="text"
                className="input-control"
                value={formData.title}
                onChange={(e) => setFormData({ ...formData, title: e.target.value })}
                placeholder="ex: Pousada Tabapitanga • Porto de Galinhas"
                required
              />
            </div>

            <div>
              <label style={{ fontSize: '0.75rem', fontWeight: 700, color: 'var(--text-muted)', marginBottom: 6, display: 'block' }}>
                Tag / Selo Visual
              </label>
              <input
                type="text"
                className="input-control"
                value={formData.tag}
                onChange={(e) => setFormData({ ...formData, tag: e.target.value })}
                placeholder="ex: 15% OFF, RECOMENDADO"
              />
            </div>
          </div>

          <div>
            <label style={{ fontSize: '0.75rem', fontWeight: 700, color: 'var(--text-muted)', marginBottom: 6, display: 'block' }}>
              Subtítulo / Descrição da Oferta
            </label>
            <textarea
              className="input-control"
              rows={2}
              value={formData.subtitle}
              onChange={(e) => setFormData({ ...formData, subtitle: e.target.value })}
              placeholder="ex: Piscinas naturais na porta do quarto, café da manhã regional e transfer incluso."
            />
          </div>

          {/* Segmentação Geográfica */}
          <div style={{ display: 'grid', gridTemplateColumns: '1fr 2fr', gap: 16 }}>
            <div>
              <label style={{ fontSize: '0.75rem', fontWeight: 700, color: 'var(--text-muted)', marginBottom: 6, display: 'block' }}>
                Estado Alvo (UF) *
              </label>
              <select
                className="input-control"
                value={formData.target_uf}
                onChange={(e) => setFormData({ ...formData, target_uf: e.target.value })}
              >
                <option value="PE">Pernambuco (PE)</option>
                <option value="AL">Alagoas (AL)</option>
                <option value="PB">Paraíba (PB)</option>
                <option value="RN">Rio Grande do Norte (RN)</option>
                <option value="CE">Ceará (CE)</option>
                <option value="BA">Bahia (BA)</option>
                <option value="SE">Sergipe (SE)</option>
                <option value="MA">Maranhão (MA)</option>
                <option value="PI">Piauí (PI)</option>
                <option value="SP">São Paulo (SP)</option>
                <option value="RJ">Rio de Janeiro (RJ)</option>
                <option value="ALL">Nacional (Todos os Estados)</option>
              </select>
            </div>

            <div>
              <label style={{ fontSize: '0.75rem', fontWeight: 700, color: 'var(--text-muted)', marginBottom: 6, display: 'block' }}>
                Cidades Alvo (Opcional - Vazio = Todo o Estado)
              </label>
              <input
                type="text"
                className="input-control"
                value={citiesInput}
                onChange={(e) => setCitiesInput(e.target.value)}
                placeholder="ex: recife, olinda, porto_de_galinhas (separadas por vírgula)"
              />
            </div>
          </div>

          {/* Mídia e Imagem com Upload e Preview */}
          <div>
            <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: 8 }}>
              <label style={{ fontSize: '0.75rem', fontWeight: 700, color: 'var(--text-muted)' }}>
                Criativo do Anúncio (Imagem de Alta Resolução) *
              </label>
              <div style={{ display: 'flex', gap: 6 }}>
                <button
                  type="button"
                  onClick={() => setImageInputMode('upload')}
                  className="btn btn-sm"
                  style={{
                    padding: '4px 10px',
                    fontSize: '0.75rem',
                    background: imageInputMode === 'upload' ? 'var(--primary)' : 'rgba(255,255,255,0.05)',
                    color: imageInputMode === 'upload' ? '#fff' : 'var(--text-muted)',
                  }}
                >
                  <UploadCloud size={13} style={{ marginRight: 4 }} />
                  Enviar Arquivo
                </button>
                <button
                  type="button"
                  onClick={() => setImageInputMode('url')}
                  className="btn btn-sm"
                  style={{
                    padding: '4px 10px',
                    fontSize: '0.75rem',
                    background: imageInputMode === 'url' ? 'var(--primary)' : 'rgba(255,255,255,0.05)',
                    color: imageInputMode === 'url' ? '#fff' : 'var(--text-muted)',
                  }}
                >
                  <LinkIcon size={13} style={{ marginRight: 4 }} />
                  Colar URL
                </button>
              </div>
            </div>

            {imageInputMode === 'upload' ? (
              <div>
                <label
                  style={{
                    border: '2px dashed var(--border-subtle)',
                    borderRadius: 'var(--radius-md)',
                    padding: '20px 16px',
                    display: 'flex',
                    flexDirection: 'column',
                    alignItems: 'center',
                    justifyContent: 'center',
                    cursor: isUploading ? 'not-allowed' : 'pointer',
                    background: isUploading ? 'rgba(59, 130, 246, 0.05)' : 'rgba(255, 255, 255, 0.02)',
                    transition: 'all 0.2s',
                  }}
                >
                  <input
                    type="file"
                    accept="image/png, image/jpeg, image/jpg, image/webp"
                    onChange={handleFileUpload}
                    disabled={isUploading}
                    style={{ display: 'none' }}
                  />
                  {isUploading ? (
                    <div style={{ display: 'flex', alignItems: 'center', gap: 10, color: 'var(--primary)' }}>
                      <Loader2 size={24} className="animate-spin" />
                      <span style={{ fontSize: '0.85rem', fontWeight: 600 }}>Enviando e salvando imagem no servidor...</span>
                    </div>
                  ) : (
                    <>
                      <UploadCloud size={28} style={{ color: 'var(--primary)', marginBottom: 8 }} />
                      <div style={{ fontSize: '0.85rem', fontWeight: 600, color: 'var(--text-main)', textAlign: 'center' }}>
                        Clique para escolher o arquivo ou arraste a imagem do anúncio aqui
                      </div>
                      <div style={{ fontSize: '0.75rem', color: 'var(--text-muted)', marginTop: 4 }}>
                        Formatos suportados: PNG, JPG, WebP • Máximo: 8MB
                      </div>
                    </>
                  )}
                </label>
                {uploadSuccess && (
                  <div style={{ marginTop: 8, fontSize: '0.75rem', color: '#10b981', display: 'flex', alignItems: 'center', gap: 6 }}>
                    <Check size={14} />
                    {uploadSuccess}
                  </div>
                )}
              </div>
            ) : (
              <div style={{ display: 'flex', gap: 10 }}>
                <input
                  type="url"
                  className="input-control"
                  value={formData.image_url}
                  onChange={(e) => setFormData({ ...formData, image_url: e.target.value })}
                  placeholder="https://exemplo.com/banner.jpg"
                  required
                />
              </div>
            )}

            {formData.image_url && (
              <div style={{ marginTop: 12, display: 'flex', alignItems: 'center', gap: 14, background: 'rgba(255,255,255,0.03)', padding: 10, borderRadius: 'var(--radius-sm)' }}>
                <div
                  style={{
                    width: 140,
                    height: 75,
                    borderRadius: 'var(--radius-sm)',
                    overflow: 'hidden',
                    border: '1px solid var(--border-subtle)',
                    background: '#1e293b',
                    flexShrink: 0,
                  }}
                >
                  <img
                    src={formData.image_url}
                    alt="Preview"
                    style={{ width: '100%', height: '100%', objectFit: 'cover' }}
                    onError={(e) => {
                      (e.target as any).src =
                        'https://placehold.co/600x400/1e293b/white?text=Imagem+Invalida';
                    }}
                  />
                </div>
                <div style={{ fontSize: '0.75rem', color: 'var(--text-muted)', wordBreak: 'break-all' }}>
                  <div style={{ fontWeight: 600, color: 'var(--text-main)', marginBottom: 2 }}>
                    ✓ Imagem vinculada ({formData.position === 'home_card' ? '16:9' : formData.position === 'interstitial' ? '9:16' : '3:1'})
                  </div>
                  <div style={{ opacity: 0.8, fontSize: '0.7rem' }}>{formData.image_url}</div>
                </div>
              </div>
            )}
          </div>

          {/* Link de Destino e CTA */}
          <div style={{ display: 'grid', gridTemplateColumns: '1fr 2fr', gap: 16 }}>
            <div>
              <label style={{ fontSize: '0.75rem', fontWeight: 700, color: 'var(--text-muted)', marginBottom: 6, display: 'block' }}>
                Texto do Botão (CTA) *
              </label>
              <input
                type="text"
                className="input-control"
                value={formData.action_label}
                onChange={(e) => setFormData({ ...formData, action_label: e.target.value })}
                placeholder="ex: Reservar no WhatsApp"
                required
              />
            </div>

            <div>
              <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 6 }}>
                <label style={{ fontSize: '0.75rem', fontWeight: 700, color: 'var(--text-muted)' }}>
                  Link de Destino (Site ou WhatsApp) *
                </label>
                <button
                  type="button"
                  onClick={() => setShowWhatsAppHelper(!showWhatsAppHelper)}
                  style={{
                    background: 'none',
                    border: 'none',
                    color: '#34d399',
                    fontSize: '0.75rem',
                    fontWeight: 700,
                    cursor: 'pointer',
                    display: 'flex',
                    alignItems: 'center',
                    gap: 4,
                  }}
                >
                  <MessageCircle size={13} />
                  <span>Gerador Link WhatsApp</span>
                </button>
              </div>

              <input
                type="url"
                className="input-control"
                value={formData.target_url}
                onChange={(e) => setFormData({ ...formData, target_url: e.target.value })}
                placeholder="https://..."
                required
              />
            </div>
          </div>

          {/* WhatsApp Helper Box */}
          {showWhatsAppHelper && (
            <div
              style={{
                padding: 16,
                borderRadius: 'var(--radius-sm)',
                background: 'rgba(16, 185, 129, 0.08)',
                border: '1px solid rgba(16, 185, 129, 0.25)',
                display: 'flex',
                flexDirection: 'column',
                gap: 12,
              }}
            >
              <div style={{ fontWeight: 700, fontSize: '0.8rem', color: '#6ee7b7' }}>
                Gerar Link Direto para o WhatsApp do Anunciante
              </div>
              <div style={{ display: 'grid', gridTemplateColumns: '1fr 2fr', gap: 10 }}>
                <input
                  type="text"
                  className="input-control"
                  placeholder="DDD + Número (ex: 81999887766)"
                  value={whatsAppPhone}
                  onChange={(e) => setWhatsAppPhone(e.target.value)}
                />
                <input
                  type="text"
                  className="input-control"
                  placeholder="Mensagem inicial automática"
                  value={whatsAppText}
                  onChange={(e) => setWhatsAppText(e.target.value)}
                />
              </div>
              <div style={{ display: 'flex', justifyContent: 'flex-end', gap: 8 }}>
                <button
                  type="button"
                  className="btn btn-secondary"
                  style={{ padding: '6px 12px', fontSize: '0.75rem' }}
                  onClick={() => setShowWhatsAppHelper(false)}
                >
                  Cancelar
                </button>
                <button
                  type="button"
                  className="btn btn-success"
                  style={{ padding: '6px 12px', fontSize: '0.75rem' }}
                  onClick={handleApplyWhatsAppLink}
                >
                  <Check size={14} />
                  <span>Aplicar Link Gerado</span>
                </button>
              </div>
            </div>
          )}

          {/* Regras de Alternância / Peso e Status */}
          <div
            style={{
              padding: 16,
              borderRadius: 'var(--radius-sm)',
              background: 'rgba(255, 255, 255, 0.03)',
              border: '1px solid var(--border-subtle)',
              display: 'flex',
              alignItems: 'center',
              justifyContent: 'space-between',
              flexWrap: 'wrap',
              gap: 16,
            }}
          >
            <div style={{ display: 'flex', alignItems: 'center', gap: 16, flex: 1, minWidth: 260 }}>
              <div style={{ flex: 1 }}>
                <div style={{ display: 'flex', justifyContent: 'space-between', marginBottom: 4 }}>
                  <label style={{ fontSize: '0.75rem', fontWeight: 700, color: 'var(--text-muted)' }}>
                    Peso na Alternância (Prioridade de Exibição):
                  </label>
                  <span style={{ fontSize: '0.825rem', fontWeight: 800, color: 'var(--primary)' }}>
                    {formData.priority} / 100
                  </span>
                </div>
                <input
                  type="range"
                  min="1"
                  max="100"
                  value={formData.priority}
                  onChange={(e) => setFormData({ ...formData, priority: Number(e.target.value) })}
                  style={{ width: '100%', accentColor: 'var(--primary)', cursor: 'pointer' }}
                />
                <div style={{ fontSize: '0.7rem', color: 'var(--text-dim)', marginTop: 2 }}>
                  * Quando houver mais de um anúncio na mesma posição, anúncios com maior peso são sorteados com maior frequência.
                </div>
              </div>
            </div>

            <div style={{ display: 'flex', alignItems: 'center', gap: 10 }}>
              <label style={{ display: 'flex', alignItems: 'center', gap: 8, cursor: 'pointer', fontWeight: 700, fontSize: '0.85rem' }}>
                <input
                  type="checkbox"
                  checked={formData.active}
                  onChange={(e) => setFormData({ ...formData, active: e.target.checked })}
                  style={{ width: 18, height: 18, accentColor: '#10b981', cursor: 'pointer' }}
                />
                <span>Campanha Ativa Imediatamente</span>
              </label>
            </div>
          </div>

          {/* Footer Controls */}
          <div
            style={{
              display: 'flex',
              alignItems: 'center',
              justifyContent: 'flex-end',
              gap: 12,
              paddingTop: 8,
              borderTop: '1px solid var(--border-subtle)',
            }}
          >
            <button type="button" onClick={onClose} className="btn btn-secondary" disabled={isSubmitting}>
              Cancelar
            </button>
            <button type="submit" className="btn btn-primary" disabled={isSubmitting}>
              {isSubmitting ? 'Salvando...' : campaignToEdit ? 'Atualizar Campanha' : 'Criar & Ativar Campanha'}
            </button>
          </div>
        </form>
      </div>
    </div>
  );
};
