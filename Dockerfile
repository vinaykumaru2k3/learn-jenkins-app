FROM mcr.microsoft.com/playwright:v1.39.0-jammy

WORKDIR /app

RUN npm install -g netlify-cli@17 serve

RUN node --version && npm --version && serve --version
