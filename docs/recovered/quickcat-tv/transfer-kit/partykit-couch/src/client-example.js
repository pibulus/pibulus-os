import PartySocket from "partysocket";

const socket = new PartySocket({
  host: "quickcat-couch-room.YOUR_PARTYKIT_USER.partykit.dev",
  room: "quickcat-prime"
});

socket.addEventListener("open", () => {
  socket.send(JSON.stringify({ type: "hello", name: "pablo" }));
});

socket.addEventListener("message", (event) => {
  const payload = JSON.parse(event.data);
  console.log("couch event", payload);
});

export function sendChat(text, name = "pablo") {
  socket.send(JSON.stringify({ type: "chat", name, text }));
}

export function bookProgram({ channel, title, startsAt, name = "pablo" }) {
  socket.send(JSON.stringify({ type: "booking", channel, title, startsAt, name }));
}

export function react(emoji, name = "pablo") {
  socket.send(JSON.stringify({ type: "reaction", emoji, name }));
}
