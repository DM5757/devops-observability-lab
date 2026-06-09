FROM node:20-alpine

WORKDIR /app

COPY package.json package-lock.json* ./
RUN npm install --omit=dev

COPY app/ ./app/

EXPOSE 3000

CMD ["npm", "start"]
