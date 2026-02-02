🗓️ Special Days Calendar
A beautiful web application that displays special holidays, observances, and celebrations for every single day of the year.

🌐 Live Demo
Website: http://44.201.53.10

Health Check: http://44.201.53.10:5000/api/health

✨ Features
🎯 Core Features
📅 366 Special Days - Every day has something special

🎨 8 Categories - Filter by type (Holidays, Science, Food, Animals, Health, Arts, Relationships, Nature)

🔍 Smart Search - Find days by name or description

🌓 Dark/Light Mode - Toggle between themes

📱 Mobile Friendly - Works on all devices

📊 Calendar Features
📈 Monthly View - Visual calendar grid

⭐ Today's Highlight - Shows today's special day

📝 Day Details - Click any day for more info

🎬 Animations - Different animations for different categories

🛠️ Tech Stack
Component	Technology
Frontend	HTML5, CSS3, JavaScript
Backend	Flask (Python)
Container	Docker + Docker Compose
Cloud	AWS EC2
Infrastructure	Terraform
Web Server	Nginx
🚀 Quick Start
Run Locally with Docker
bash
# Clone the repository
git clone https://github.com/Arulraj25/365days-special-calender.git
cd 365days-special-calender

# Start the application
docker-compose up -d

# Access the app:
# Website: http://localhost
# API: http://localhost:5000
Manual Setup
bash
# Backend (Python)
cd backend
pip install -r requirements.txt
python app.py

# Frontend (Open in browser)
cd frontend
# Open index.html in your browser
☁️ Deploy to AWS
Using Terraform
bash
# 1. Configure AWS
export AWS_ACCESS_KEY_ID="your-key"
export AWS_SECRET_ACCESS_KEY="your-secret"

# 2. Deploy infrastructure
terraform init
terraform plan
terraform apply -auto-approve

# 3. Deploy application
scp -r backend/ frontend/ docker-compose.yml ec2-user@YOUR_IP:/home/ec2-user/
ssh ec2-user@YOUR_IP "cd /home/ec2-user && docker-compose up -d"
Manual Deployment
bash
# SSH to your EC2 instance
ssh -i your-key.pem ec2-user@YOUR_IP

# Install Docker
sudo yum install -y docker
sudo systemctl start docker
sudo systemctl enable docker

# Install Docker Compose
sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

# Run the app
docker-compose up -d
📡 API Documentation
Base URL
http://your-server:5000

Available Endpoints
Method	Endpoint	Description
GET	/api/special-days	All 366 special days
GET	/api/today	Today's special day
GET	/api/health	Health check
GET	/api/month/{1-12}	Days by month
GET	/api/category/{name}	Days by category
Example API Response
json
{
  "date": "02-14",
  "day": "Valentine's Day",
  "description": "Day of love and affection",
  "icon": "fas fa-heart",
  "color": "#E91E63",
  "animation": "hearts",
  "category": "relationships"
}
📁 Project Structure
text
365days-special-calender/
├── backend/                    # Flask backend
│   ├── app.py                 # Main Flask application
│   ├── requirements.txt       # Python dependencies
│   └── Dockerfile            # Docker configuration
├── frontend/                  # Frontend website
│   ├── index.html            # Main HTML file
│   ├── style.css             # CSS styles
│   ├── script.js             # JavaScript logic
│   ├── nginx.conf            # Nginx configuration
│   └── Dockerfile            # Docker configuration
├── docker-compose.yml        # Multi-container setup
├── main.tf                   # Terraform AWS configuration
├── Jenkinsfile               # CI/CD pipeline
└── README.md                 # This file
🐳 Docker Commands
bash
# Build and start
docker-compose up -d --build

# View logs
docker-compose logs -f

# Stop containers
docker-compose down

# Restart services
docker-compose restart

# Check container status
docker-compose ps
🎨 Categories
Category	Color	Icon	Example Days
Holidays	Orange	🎉	New Year's, Christmas
Science/Tech	Blue	🔬	Pi Day, Science Day
Food	Red	🍕	Pizza Day, Chocolate Day
Animals	Green	🐾	Bird Day, Cat Day
Health	Teal	🏥	Health Day, Yoga Day
Arts/Culture	Purple	🎨	Book Day, Music Day
Relationships	Pink	❤️	Valentine's, Friendship
Nature	Green	🌿	Earth Day, Tree Day
🔧 Troubleshooting
Common Issues
Port already in use

bash
# Stop existing containers
docker-compose down
# Or kill process on port 80/5000
sudo lsof -ti:80 | xargs kill -9
Docker permission issues

bash
sudo usermod -aG docker $USER
newgrp docker
AWS connection issues

bash
# Check AWS credentials
aws configure list
# Test connection
aws ec2 describe-instances
📄 License
This project is licensed under the MIT License - see the LICENSE file for details.

👥 Author
Arulraj

GitHub: @Arulraj25

Project: 365days-special-calender

🙏 Acknowledgments
Icons from Font Awesome

Fonts from Google Fonts

Color palette from Material Design

AWS for cloud infrastructure

⭐ Star this repo if you find it useful! ⭐
