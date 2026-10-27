import {
  OverviewStats,
  AdPerformanceItem,
  HouseAdCampaign,
  PlaceReviewItem,
  PlaceStatsItem,
  PbCityItem,
  PbAttractionItem,
} from '../types';

export const API_BASE_URL =
  import.meta.env.VITE_API_BASE_URL || 'https://onetour-api-onetour.gtalg3.easypanel.host';
export const PB_BASE_URL =
  import.meta.env.VITE_POCKETBASE_URL || 'https://onetour-pocketbase-estados.gtalg3.easypanel.host';

const TOKEN_KEY = 'onetour_admin_token';
const EMAIL_KEY = 'onetour_admin_email';

export function getStoredToken(): string | null {
  return localStorage.getItem(TOKEN_KEY);
}

export function getStoredEmail(): string | null {
  return localStorage.getItem(EMAIL_KEY);
}

export function setStoredAuth(token: string, email: string): void {
  localStorage.setItem(TOKEN_KEY, token);
  localStorage.setItem(EMAIL_KEY, email);
}

export function clearStoredAuth(): void {
  localStorage.removeItem(TOKEN_KEY);
  localStorage.removeItem(EMAIL_KEY);
}

async function requestApi<T>(path: string, options: RequestInit = {}): Promise<T> {
  const token = getStoredToken();
  const headers: Record<string, string> = {
    'Content-Type': 'application/json',
    ...(options.headers as Record<string, string>),
  };
  if (token) {
    headers['Authorization'] = `Bearer ${token}`;
  }

  const res = await fetch(`${API_BASE_URL}${path}`, {
    ...options,
    headers,
  });

  if (!res.ok) {
    const errorData = await res.json().catch(() => ({}));
    throw new Error(errorData.error || `Erro HTTP ${res.status}: ${res.statusText}`);
  }

  return res.json();
}

async function requestPb<T>(path: string, options: RequestInit = {}): Promise<T> {
  const token = getStoredToken();
  const headers: Record<string, string> = {
    'Content-Type': 'application/json',
    ...(options.headers as Record<string, string>),
  };
  if (token) {
    headers['Authorization'] = token;
  }

  const res = await fetch(`${PB_BASE_URL}${path}`, {
    ...options,
    headers,
  });

  if (!res.ok) {
    const errorData = await res.json().catch(() => ({}));
    throw new Error(errorData.message || `Erro PocketBase ${res.status}`);
  }

  return res.json();
}

// ---------------------------------------------------------------------------
// One Tour API Endpoints
// ---------------------------------------------------------------------------

export async function fetchOverviewStats(): Promise<OverviewStats> {
  const res = await requestApi<{ success: boolean; data: OverviewStats }>('/api/v1/admin/overview');
  return res.data;
}

export async function fetchAdPerformance(days: number = 30): Promise<AdPerformanceItem[]> {
  const res = await requestApi<{ success: boolean; rows: AdPerformanceItem[] }>(
    `/api/v1/admin/ads/performance?days=${days}`
  );
  return res.rows;
}

export async function fetchCampaigns(uf?: string, position?: string): Promise<HouseAdCampaign[]> {
  const params = new URLSearchParams();
  if (uf && uf !== 'ALL') params.set('uf', uf);
  if (position && position !== 'all') params.set('position', position);
  const q = params.toString() ? `?${params.toString()}` : '';
  const res = await requestApi<{ success: boolean; data: HouseAdCampaign[] }>(`/api/v1/admin/campaigns${q}`);
  return res.data || [];
}

export async function createCampaign(campaign: Partial<HouseAdCampaign>): Promise<HouseAdCampaign> {
  const res = await requestApi<{ success: boolean; data: HouseAdCampaign }>('/api/v1/admin/campaigns', {
    method: 'POST',
    body: JSON.stringify(campaign),
  });
  return res.data;
}

export async function updateCampaign(id: string, campaign: Partial<HouseAdCampaign>): Promise<HouseAdCampaign> {
  const res = await requestApi<{ success: boolean; data: HouseAdCampaign }>(`/api/v1/admin/campaigns/${encodeURIComponent(id)}`, {
    method: 'PUT',
    body: JSON.stringify(campaign),
  });
  return res.data;
}

export async function toggleCampaignActive(id: string, active: boolean): Promise<HouseAdCampaign> {
  const res = await requestApi<{ success: boolean; data: HouseAdCampaign }>(`/api/v1/admin/campaigns/${encodeURIComponent(id)}/toggle`, {
    method: 'PATCH',
    body: JSON.stringify({ active }),
  });
  return res.data;
}

export async function deleteCampaign(id: string): Promise<void> {
  await requestApi(`/api/v1/admin/campaigns/${encodeURIComponent(id)}`, {
    method: 'DELETE',
  });
}

export async function fetchReviews(uf: string = 'PE', placeId?: string): Promise<PlaceReviewItem[]> {
  const q = placeId ? `&place_id=${encodeURIComponent(placeId)}` : '';
  const res = await requestApi<{ success: boolean; rows: PlaceReviewItem[] }>(
    `/api/v1/admin/reviews?uf=${uf}${q}`
  );
  return res.rows;
}

export async function toggleHideReview(
  placeId: string,
  deviceId: string,
  hidden: boolean
): Promise<void> {
  await requestApi('/api/v1/admin/reviews/hide', {
    method: 'PATCH',
    body: JSON.stringify({ place_id: placeId, device_id: deviceId, hidden }),
  });
}

export async function updateEditorialWeight(
  placeId: string,
  uf: string,
  citySlug: string,
  weight: number
): Promise<void> {
  await requestApi(`/api/v1/admin/places/${encodeURIComponent(placeId)}/editorial`, {
    method: 'PUT',
    body: JSON.stringify({ uf, city_slug: citySlug, editorial_weight: weight }),
  });
}

export async function triggerRecalculateRankings(): Promise<{ places: number }> {
  return requestApi<{ success: boolean; places: number }>('/api/v1/admin/rankings/recalculate', {
    method: 'POST',
  });
}

export async function fetchPlaceStats(uf: string = 'PE'): Promise<PlaceStatsItem[]> {
  const res = await requestApi<{ success: boolean; data: PlaceStatsItem[] }>(
    `/api/v1/places/stats?uf=${uf}`
  );
  return res.data;
}

// ---------------------------------------------------------------------------
// PocketBase Auth & CMS
// ---------------------------------------------------------------------------

export async function loginAdmin(identity: string, password: string): Promise<string> {
  // PocketBase v0.23+ autentica superusers na coleção _superusers
  let res = await fetch(`${PB_BASE_URL}/api/collections/_superusers/auth-with-password`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ identity, password }),
  });

  // Fallback para PocketBase v0.22 (admins) caso retorne 404
  if (res.status === 404) {
    res = await fetch(`${PB_BASE_URL}/api/admins/auth-with-password`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ identity, password }),
    });
  }

  if (!res.ok) {
    const errorData = await res.json().catch(() => ({}));
    throw new Error(errorData.message || 'Credenciais de administrador inválidas');
  }

  const data = await res.json();
  const token = data.token;
  const email = data.record?.email || data.admin?.email || identity;
  setStoredAuth(token, email);
  return token;
}

export async function fetchPbCities(uf: string = 'PE'): Promise<PbCityItem[]> {
  try {
    const res = await requestPb<{ items: PbCityItem[] }>(
      `/api/collections/cidades/records?filter=(estado_sigla="${uf.toUpperCase()}")&perPage=50`
    );
    return res.items || [];
  } catch {
    return [];
  }
}

export async function fetchPbAttractions(uf: string = 'PE'): Promise<PbAttractionItem[]> {
  try {
    const res = await requestPb<{ items: PbAttractionItem[] }>(
      `/api/collections/atracoes/records?filter=(uf="${uf.toUpperCase()}")&perPage=100&sort=-score`
    );
    return res.items || [];
  } catch {
    return [];
  }
}

export async function sendPushNotification(payload: import('../types').PushNotificationPayload): Promise<{
  success: boolean;
  message_id: string;
  topic: string;
  broadcast_at: string;
}> {
  return requestApi('/api/v1/admin/notifications/send', {
    method: 'POST',
    body: JSON.stringify(payload),
  });
}

/** Faz upload de arquivo de imagem do anúncio para o House Ads server */
export async function uploadAdImage(file: File): Promise<{ url: string; filename: string; sizeBytes: number }> {
  return new Promise((resolve, reject) => {
    const reader = new FileReader();
    reader.onload = async () => {
      try {
        const base64Data = reader.result as string;
        const res = await requestApi<{ success: boolean; url: string; filename: string; sizeBytes: number }>(
          '/api/v1/admin/ads/upload',
          {
            method: 'POST',
            body: JSON.stringify({
              data: base64Data,
              filename: file.name,
            }),
          }
        );
        resolve(res);
      } catch (err) {
        reject(err);
      }
    };
    reader.onerror = () => reject(new Error('Erro ao ler o arquivo selecionado.'));
    reader.readAsDataURL(file);
  });
}

