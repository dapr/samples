FROM node:10

WORKDIR /app/
COPY . /app/

RUN npm install --only=production

EXPOSE 3002

CMD [ "node", "app.js" ]