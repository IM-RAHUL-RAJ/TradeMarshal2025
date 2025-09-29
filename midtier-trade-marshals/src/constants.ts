// interface Config {
//     BACKEND_URL: string,
//     FRONTEND_URL: string
//     // Add other configuration settings here, e.g., API keys, timeouts
//   }
  
const defaultConfig = {
  // FRONTEND_URL: 'http://localhost:4200',
  // BACKEND_URL: 'http://localhost:8080/'
  FRONTEND_URL: 'http://ace451fb6ae544b83968233d385b6c66-1700287478.ap-south-1.elb.amazonaws.com:4200',
  BACKEND_URL: 'http://a012288d25cc14600a55bd65ec5e1329-819930508.ap-south-1.elb.amazonaws.com:8080/',
};

//const config = { ...defaultConfig };

export default defaultConfig;
