const DEFAULT_API_BASE_URL = 'https://localhost:7062';

export const API_BASE_URL = (import.meta.env.VITE_API_BASE_URL ?? DEFAULT_API_BASE_URL).replace(/\/+$/, '');

export class ApiError extends Error {
  constructor(message: string, public readonly status: number) {
    super(message);
    this.name = 'ApiError';
  }
}

export const buildApiUrl = (path: string) => {
  if (/^https?:\/\//i.test(path)) {
    return path;
  }

  const normalizedPath = path.startsWith('/') ? path : `/${path}`;
  return `${API_BASE_URL}${normalizedPath}`;
};

export async function apiRequest<T>(path: string, options: RequestInit = {}): Promise<T> {
  const headers = new Headers(options.headers);

  if (!(options.body instanceof FormData) && !headers.has('Content-Type') && options.method && options.method !== 'GET' && options.body) {
    headers.set('Content-Type', 'application/json');
  }

  const response = await fetch(buildApiUrl(path), {
    ...options,
    headers,
    credentials: options.credentials ?? 'include',
  });

  if (response.status === 204) {
    return undefined as T;
  }

  const text = await response.text();
  let payload: unknown = null;

  if (text) {
    try {
      payload = JSON.parse(text);
    } catch {
      payload = text;
    }
  }

  if (!response.ok) {
    const message =
      typeof payload === 'object' && payload !== null && 'message' in payload && typeof (payload as { message?: unknown }).message === 'string' ? (payload as { message: string }).message :
      typeof payload === 'object' && payload !== null && 'title' in payload && typeof (payload as { title?: unknown }).title === 'string' ? (payload as { title: string }).title :
      `Ошибка запроса (${response.status})`;

    throw new ApiError(message, response.status);
  }

  return payload as T;
}
