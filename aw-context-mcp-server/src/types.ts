export interface ContextEntry {
  id: string;
  timestamp: string;
  context: string;
  tags: string[];
}

export interface ActivityWatchEvent {
  id?: number;
  timestamp: string;
  duration: number;
  data: {
    app: string;
    title: string;
  };
}

export interface EnrichedEvent extends ActivityWatchEvent {
  context?: string;
  tags?: string[];
}