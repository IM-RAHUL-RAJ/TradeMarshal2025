

import express from 'express';
import { Request, Response } from 'express';
// Add Node.js type definitions for require/module
// @ts-ignore
declare var require: any;
// @ts-ignore
declare var module: any;

import cors from 'cors';

import defaultConfig from './constants'; 

//Importing routes
import healthRoutes from './routes/health-route';
import clientRoutes from './routes/client-routes';
import clientPreferencesRoutes from './routes/client-preferences-routes';
import portfolioRoutes from './routes/portfolio-routes'
import tradeRoutes from './routes/trade-routes'
import activityReportRoutes from './routes/activity-report-routes'

class App {

    port: number
    app: any

    constructor() {
        this.port = 4000; //Midtier Port
        this.app = express();
        // Configure Express to populate a request body from JSON input
        this.app.use(express.json());

        //Enabling CORS policy for all origins (for testing only)
        this.app.use(cors({
            origin: '*',
            methods: 'GET,POST,PUT,DELETE',
            allowedHeaders: 'Content-Type,Authorization'
        }));

        // Defining Routes
        this.app.use('/', healthRoutes); // Health route will be at the root level
        this.app.use('/client', clientRoutes); // All client-related routes 
        this.app.use('/client-preferences', clientPreferencesRoutes); // All client preferences-related routes 
        this.app.use('/portfolio', portfolioRoutes); // All client portfolio-related routes 
        this.app.use('/trade', tradeRoutes); // All trade-related routes 
        this.app.use('/activity-report', activityReportRoutes); // All activity report-related routes 

        // Handle unmatched routes
        this.app.use((req:Request, res:Response) => {
            res.status(404).json({ message: 'Path not found. Please check your URL' });
        });
    }

    start() {
        this.app.listen(this.port,
            () => console.log(`Midtier of Trade Marshals listening on port ${this.port}`))
    }

}

export default new App().app;

if (require.main === module) {
    const api = new App();
    api.start();
}