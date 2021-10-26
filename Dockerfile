FROM node:16.10.0
RUN mkdir /app
COPY ./ /app
WORKDIR /app
CMD npm run serve