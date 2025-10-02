// interface Config {
//     BACKEND_URL: string,
//     FRONTEND_URL: string
//     // Add other configuration settings here, e.g., API keys, timeouts
//   }
  
const defaultConfig = {
  // FRONTEND_URL: 'http://localhost:4200',
  // BACKEND_URL: 'http://localhost:8080/'
  // When running inside cluster with Ingress, external host not needed here; used only for CORS if referenced.
  // You can set an environment variable to override for production domain.
  FRONTEND_URL: 'http://localhost:4200', // or set to your final domain via env var if code reads it
  BACKEND_URL: 'http://spring-app:8080/',
};

//const config = { ...defaultConfig };

export default defaultConfig;
