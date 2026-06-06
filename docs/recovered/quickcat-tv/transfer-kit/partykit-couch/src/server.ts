import type * as Party from "partykit/server";

type ChatMessage = {
  id: string;
  name: string;
  text: string;
  ts: number;
};

type Booking = {
  id: string;
  channel: number;
  title: string;
  name: string;
  startsAt: string;
  ts: number;
};

type ClientEvent =
  | { type: "hello"; name?: string }
  | { type: "chat"; name?: string; text?: string }
  | { type: "booking"; channel?: number; title?: string; name?: string; startsAt?: string }
  | { type: "reaction"; emoji?: string; name?: string };

const MAX_MESSAGES = 80;
const MAX_BOOKINGS = 40;

export default class CouchRoom implements Party.Server {
  constructor(readonly room: Party.Room) {}

  async onConnect(connection: Party.Connection) {
    const [messages, bookings] = await Promise.all([
      this.getMessages(),
      this.getBookings()
    ]);

    connection.send(JSON.stringify({
      type: "sync",
      room: this.room.id,
      messages,
      bookings,
      ts: Date.now()
    }));

    this.room.broadcast(JSON.stringify({
      type: "presence",
      action: "join",
      id: connection.id,
      ts: Date.now()
    }));
  }

  async onClose(connection: Party.Connection) {
    this.room.broadcast(JSON.stringify({
      type: "presence",
      action: "leave",
      id: connection.id,
      ts: Date.now()
    }));
  }

  async onMessage(raw: string, connection: Party.Connection) {
    const event = this.parseEvent(raw);
    if (!event) {
      connection.send(JSON.stringify({ type: "error", message: "bad_event" }));
      return;
    }

    if (event.type === "chat") {
      const text = cleanText(event.text, 280);
      if (!text) return;

      const message: ChatMessage = {
        id: crypto.randomUUID(),
        name: cleanText(event.name, 40) || "couch",
        text,
        ts: Date.now()
      };

      const messages = [...await this.getMessages(), message].slice(-MAX_MESSAGES);
      await this.room.storage.put("messages", messages);
      this.room.broadcast(JSON.stringify({ type: "chat", message }));
      return;
    }

    if (event.type === "booking") {
      const title = cleanText(event.title, 120);
      const startsAt = cleanText(event.startsAt, 40);
      const channel = Number(event.channel);
      if (!title || !startsAt || !Number.isInteger(channel)) return;

      const booking: Booking = {
        id: crypto.randomUUID(),
        channel,
        title,
        startsAt,
        name: cleanText(event.name, 40) || "couch",
        ts: Date.now()
      };

      const bookings = [...await this.getBookings(), booking].slice(-MAX_BOOKINGS);
      await this.room.storage.put("bookings", bookings);
      this.room.broadcast(JSON.stringify({ type: "booking", booking }));
      return;
    }

    if (event.type === "reaction") {
      this.room.broadcast(JSON.stringify({
        type: "reaction",
        emoji: cleanText(event.emoji, 8) || "*",
        name: cleanText(event.name, 40) || "couch",
        ts: Date.now()
      }));
      return;
    }

    if (event.type === "hello") {
      this.room.broadcast(JSON.stringify({
        type: "presence",
        action: "hello",
        id: connection.id,
        name: cleanText(event.name, 40) || "couch",
        ts: Date.now()
      }));
    }
  }

  private async getMessages(): Promise<ChatMessage[]> {
    return (await this.room.storage.get<ChatMessage[]>("messages")) ?? [];
  }

  private async getBookings(): Promise<Booking[]> {
    return (await this.room.storage.get<Booking[]>("bookings")) ?? [];
  }

  private parseEvent(raw: string): ClientEvent | null {
    try {
      const event = JSON.parse(raw) as ClientEvent;
      return typeof event?.type === "string" ? event : null;
    } catch {
      return null;
    }
  }
}

function cleanText(value: unknown, limit: number): string {
  if (typeof value !== "string") return "";
  return value.replace(/\s+/g, " ").trim().slice(0, limit);
}
