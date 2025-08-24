# Deployment Guide for LeetCode Spaced on DigitalOcean

This guide will walk you through deploying the LeetCode Spaced application on a DigitalOcean Droplet using Docker.

## Prerequisites

1. A DigitalOcean account
2. A domain name (optional, but recommended for SSL)
3. Google OAuth credentials configured
4. Your local development environment set up

## Step 1: Create a DigitalOcean Droplet

1. Log in to your DigitalOcean account
2. Create a new Droplet with these specifications:
   - **Image**: Ubuntu 22.04 LTS
   - **Size**: Basic plan, $12/month (2GB RAM, 1 vCPU, 50GB SSD)
   - **Region**: Choose closest to your users
   - **Authentication**: SSH keys (recommended) or password
   - **Options**: Enable monitoring and backups (optional)

3. Note your droplet's IP address

## Step 2: Configure DNS (Optional)

If you have a domain:
1. Add an A record pointing to your droplet's IP address
2. Wait for DNS propagation (5-30 minutes)

## Step 3: Prepare Environment Variables

1. Copy the example environment file:
   ```bash
   cp .env.example .env
   ```

2. Generate a secret key base:
   ```bash
   mix phx.gen.secret
   ```

3. Edit `.env` and fill in all values:
   ```env
   # Database Configuration
   POSTGRES_USER=leetcode_user
   POSTGRES_PASSWORD=<generate-secure-password>
   POSTGRES_DB=leetcode_spaced

   # Phoenix Configuration
   SECRET_KEY_BASE=<your-generated-secret>
   PHX_HOST=your-domain.com  # or droplet IP
   POOL_SIZE=10

   # Google OAuth
   GOOGLE_CLIENT_ID=<your-google-client-id>
   GOOGLE_CLIENT_SECRET=<your-google-client-secret>
   ```

## Step 4: Initial Server Setup

Run the deployment script with the `--init` flag for first-time setup:

```bash
./deploy.sh <droplet-ip> root --init
```

This will:
- Install Docker and Docker Compose
- Set up necessary directories
- Configure swap space for better performance
- Install Nginx for reverse proxy

## Step 5: Deploy the Application

Deploy your application:

```bash
./deploy.sh <droplet-ip> root
```

This will:
- Copy your application files to the droplet
- Build the Docker image
- Start PostgreSQL and run migrations
- Start the Phoenix application

## Step 6: Set Up SSL (Optional but Recommended)

If you have a domain configured:

```bash
./deploy.sh <droplet-ip> root --ssl your-domain.com
```

This will automatically obtain and configure a Let's Encrypt SSL certificate.

## Step 7: Configure Google OAuth

1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Navigate to APIs & Services > Credentials
3. Update your OAuth 2.0 Client ID with:
   - Authorized JavaScript origins: `https://your-domain.com`
   - Authorized redirect URIs: `https://your-domain.com/auth/google/callback`

## Monitoring and Maintenance

### View Logs
```bash
ssh root@<droplet-ip> 'cd /var/www/leetcode_spaced && docker-compose -f docker-compose.prod.yml logs -f'
```

### Restart Application
```bash
ssh root@<droplet-ip> 'cd /var/www/leetcode_spaced && docker-compose -f docker-compose.prod.yml restart'
```

### Update Application
```bash
# Pull latest changes locally
git pull origin main

# Deploy update
./deploy.sh <droplet-ip> root
```

### Database Backup
```bash
ssh root@<droplet-ip> 'docker exec leetcode_spaced_postgres pg_dump -U leetcode_user leetcode_spaced > backup.sql'
```

### Database Restore
```bash
ssh root@<droplet-ip> 'docker exec -i leetcode_spaced_postgres psql -U leetcode_user leetcode_spaced < backup.sql'
```

## CI/CD with GitHub Actions

The repository includes a GitHub Actions workflow for automated deployment.

### Setup GitHub Secrets

Add these secrets to your repository (Settings > Secrets and variables > Actions):

1. `DROPLET_IP`: Your DigitalOcean droplet IP address
2. `SSH_PRIVATE_KEY`: Your SSH private key for droplet access

To get your SSH private key:
```bash
cat ~/.ssh/id_rsa  # or your key path
```

### Automated Deployment

Once configured, every push to the `main` branch will:
1. Run tests
2. Build Docker image
3. Push to GitHub Container Registry
4. Deploy to your DigitalOcean droplet

## Troubleshooting

### Application won't start
1. Check logs: `docker-compose -f docker-compose.prod.yml logs app`
2. Verify environment variables are set correctly
3. Ensure database is running: `docker-compose -f docker-compose.prod.yml ps`

### Database connection issues
1. Check PostgreSQL is running: `docker ps | grep postgres`
2. Verify database credentials in `.env`
3. Test connection: `docker exec -it leetcode_spaced_postgres psql -U leetcode_user`

### SSL certificate issues
1. Ensure domain DNS is properly configured
2. Check Nginx configuration: `nginx -t`
3. Renew certificate: `certbot renew`

### Out of memory errors
1. Check swap is enabled: `free -h`
2. Consider upgrading to a larger droplet
3. Optimize `POOL_SIZE` in `.env`

## Security Recommendations

1. **Use SSH keys** instead of passwords for droplet access
2. **Enable firewall** (ufw) and only allow ports 22, 80, 443
3. **Regular updates**: `apt update && apt upgrade`
4. **Enable automatic security updates**
5. **Use strong passwords** for database
6. **Regular backups** of database and uploads
7. **Monitor logs** for suspicious activity

## Cost Optimization

Total monthly cost: ~$12-15/month
- Droplet: $12/month (2GB RAM)
- Backups: $2.40/month (optional)
- Domain: ~$1/month (if using)

This is much cheaper than:
- Fly.io with PostgreSQL: ~$40+/month
- Heroku: ~$25+/month
- AWS/GCP: Variable, often $30+/month

## Support

For issues specific to:
- Phoenix/Elixir: Check the [Phoenix documentation](https://hexdocs.pm/phoenix)
- Docker: See [Docker documentation](https://docs.docker.com/)
- DigitalOcean: Visit [DigitalOcean community](https://www.digitalocean.com/community)
- This deployment: Open an issue in the repository