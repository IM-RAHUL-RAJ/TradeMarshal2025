FROM node:14 AS build

# Set the working directory
WORKDIR /frontend-trade-marshals

# Copy package.json and package-lock.json
COPY package*.json ./

# Install dependencies
RUN npm install

# Install Angular CLI and specific versions of packages
RUN npm install -g @angular/cli@12
#RUN npm install @angular-devkit/build-angular@13.1.13 --force

# Copy the rest of the application code
COPY . .

# Build the Angular app for production
RUN ng build --configuration=production

FROM nginx:alpine
# Copy the build output to nginx html directory
COPY --from=build /frontend-trade-marshals/dist/frontend-trade-marshals /usr/share/nginx/html
EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]