import { createApp } from "./app.js";
import { config } from "./config.js";

const app = createApp();

app.listen(config.app.port, () => {
  console.log(`${config.app.name} backend running on http://127.0.0.1:${config.app.port}`);
});
