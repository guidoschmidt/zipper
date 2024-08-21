export async function passToWorker(e: { data: [URL, string] }) {
  const [url, data] = e.data;
  await fetch(url, {
    method: "POST",
    body: JSON.stringify(data),
  });
  this.postMessage(true);
}
