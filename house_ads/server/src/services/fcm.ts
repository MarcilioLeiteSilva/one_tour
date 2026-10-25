import { initializeApp, cert, getApps, App } from 'firebase-admin/app';
import { getMessaging, Message } from 'firebase-admin/messaging';
import fs from 'fs';
import path from 'path';

let firebaseApp: App | null = null;

/**
 * Inicializa o Firebase Admin SDK com credenciais de Conta de Serviço.
 * Procura primeiro na variável de ambiente FIREBASE_SERVICE_ACCOUNT (ideal para Easypanel/Docker)
 * e depois em arquivos locais no disco.
 */
export function initFirebase(): boolean {
  if (firebaseApp || getApps().length > 0) {
    if (!firebaseApp && getApps().length > 0) {
      firebaseApp = getApps()[0];
    }
    return true;
  }

  try {
    let serviceAccount: any = null;

    // 1. Variável de ambiente (JSON string ou base64) para produção no Easypanel
    if (process.env.FIREBASE_SERVICE_ACCOUNT) {
      try {
        const raw = process.env.FIREBASE_SERVICE_ACCOUNT.trim();
        const jsonStr = raw.startsWith('{') ? raw : Buffer.from(raw, 'base64').toString('utf8');
        serviceAccount = JSON.parse(jsonStr);
      } catch (err: any) {
        console.warn('⚠️ Falha ao decodificar FIREBASE_SERVICE_ACCOUNT da env:', err.message);
      }
    }

    // 2. Arquivo local no disco (desenvolvimento / montagem local)
    if (!serviceAccount) {
      const candidates = [
        process.env.FIREBASE_SERVICE_ACCOUNT_PATH,
        path.resolve(process.cwd(), 'keys_firebase/app-onetour-firebase-adminsdk-fbsvc-938705d63f.json'),
        path.resolve(process.cwd(), '../keys_firebase/app-onetour-firebase-adminsdk-fbsvc-938705d63f.json'),
        path.resolve(process.cwd(), '../../keys_firebase/app-onetour-firebase-adminsdk-fbsvc-938705d63f.json'),
      ].filter(Boolean) as string[];

      for (const p of candidates) {
        if (fs.existsSync(p)) {
          serviceAccount = JSON.parse(fs.readFileSync(p, 'utf8'));
          console.log(`🔑 Firebase Service Account carregada do arquivo: ${p}`);
          break;
        }
      }
    }

    if (serviceAccount && serviceAccount.project_id) {
      firebaseApp = initializeApp({
        credential: cert(serviceAccount),
        projectId: serviceAccount.project_id,
      });
      console.log(`✅ Firebase Admin SDK conectado com sucesso ao projeto: ${serviceAccount.project_id}`);
      return true;
    }
  } catch (err: any) {
    console.warn('⚠️ Erro ao inicializar Firebase Admin SDK:', err.message);
  }

  console.warn('ℹ️ Firebase Service Account não encontrada. Push funcionará em modo fallback/simulado.');
  return false;
}

export interface SendPushParams {
  topic?: string;
  deviceToken?: string;
  title: string;
  body: string;
  imageUrl?: string;
  actionType?: string;
  actionValue?: string;
  data?: Record<string, string>;
}

export interface PushResult {
  success: boolean;
  messageId: string;
  target: string;
  isRealDispatch: boolean;
  broadcastAt: string;
}

/**
 * Dispara notificação push via Google Firebase Cloud Messaging (FCM).
 * Se tiver topic: envia para todos os aparelhos inscritos no tópico (ex: pe_geral, pe_recife).
 * Se tiver deviceToken: envia diretamente para o aparelho específico.
 */
export async function sendFcmPush(params: SendPushParams): Promise<PushResult> {
  const initialized = initFirebase();
  const timestamp = new Date().toISOString();

  const dataPayload: Record<string, string> = {
    click_action: 'FLUTTER_NOTIFICATION_CLICK',
    title: params.title,
    body: params.body,
    action_type: params.actionType || 'open_city',
    action_value: params.actionValue || 'recife',
    timestamp,
    ...(params.data || {}),
  };

  if (params.imageUrl) {
    dataPayload.image_url = params.imageUrl;
  }

  if (initialized && firebaseApp) {
    try {
      const messaging = getMessaging(firebaseApp);
      let responseMessageId: string;
      let targetDesc: string;

      if (params.deviceToken) {
        targetDesc = `token:${params.deviceToken.substring(0, 10)}...`;
        const message: Message = {
          token: params.deviceToken,
          notification: {
            title: params.title,
            body: params.body,
            imageUrl: params.imageUrl || undefined,
          },
          data: dataPayload,
          android: {
            priority: 'high',
            notification: {
              channelId: 'onetour_notifications',
              priority: 'high',
              defaultSound: true,
              defaultVibrateTimings: true,
              imageUrl: params.imageUrl || undefined,
            },
          },
        };
        responseMessageId = await messaging.send(message);
      } else {
        const cleanTopic = (params.topic || 'pe_geral').replace(/^\/topics\//, '').trim().toLowerCase();
        targetDesc = `/topics/${cleanTopic}`;
        dataPayload.topic = cleanTopic;

        const message: Message = {
          topic: cleanTopic,
          notification: {
            title: params.title,
            body: params.body,
            imageUrl: params.imageUrl || undefined,
          },
          data: dataPayload,
          android: {
            priority: 'high',
            notification: {
              channelId: 'onetour_notifications',
              priority: 'high',
              defaultSound: true,
              defaultVibrateTimings: true,
              imageUrl: params.imageUrl || undefined,
            },
          },
        };
        responseMessageId = await messaging.send(message);
      }

      console.log(`🚀 [FCM REAL DISPATCH] Sucesso para ${targetDesc} | ID: ${responseMessageId}`);
      return {
        success: true,
        messageId: responseMessageId,
        target: targetDesc,
        isRealDispatch: true,
        broadcastAt: timestamp,
      };
    } catch (err: any) {
      console.error('❌ [FCM REAL DISPATCH ERROR]', err.message);
      throw err;
    }
  }

  // Fallback simulado se não houver chave
  const cleanTopic = (params.topic || 'pe_geral').replace(/^\/topics\//, '').trim().toLowerCase();
  const mockId = `simulated_fcm_${Date.now()}_${Math.random().toString(36).substring(2, 8)}`;
  console.log(`ℹ️ [FCM SIMULADO] Disparado para /topics/${cleanTopic}: "${params.title}"`);

  return {
    success: true,
    messageId: mockId,
    target: `/topics/${cleanTopic}`,
    isRealDispatch: false,
    broadcastAt: timestamp,
  };
}
