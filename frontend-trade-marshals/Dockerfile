FROM node:20 AS build

# Set the working directory
WORKDIR /frontend-trade-marshals

# Copy package.json and package-lock.json
COPY package*.json ./

# Install dependencies (includes dev deps needed for build)
RUN npm install

# Install Angular CLI matching project major version (15)
RUN npm install -g @angular/cli@15.1.2

# Copy the rest of the application code
COPY . .

# Build the Angular app for production
RUN ng build --configuration=production

FROM nginx:alpine
# Copy the build output to nginx html directory
COPY --from=build /frontend-trade-marshals/dist/frontend-trade-marshals /usr/share/nginx/html
EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]