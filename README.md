# tf-aws-django-website
I created this website to support my ongoing research and experimentaiton with AI/LLM's.  Its not currently deployed for this purpose because i've created an application/ecosystem at work in the space of AI and am actively pouring my time/energy into scaling it out to hundreds of users.

This repository contains the infrastructure as code (IaC) for deploying a Django website on AWS using Terraform. The Django website is containerized using Docker and orchestrated using AWS ECS Fargate.

## Usage/permission

This repo was designed for personal use and I am not permitting others to deploy it as-is at this time.

- In order to share this repo I may refactor it in the future into a stack that others can deploy
- However, this will not include the django based html that I have customized for my site and style.

## Public Repository Purpose

So, you may rightfully ask why have this public at all then? Great question!

- Having an application that I can continue to evolve is tied to the purpose of my blog, which is researching/experimenting with LLM/AI.
- The code I share on my blog will be tied to this repo, among others, to give additional context on what I am up to.

## Architecture

The production architecture of the application is as follows:

- A client makes a secure HTTPS request to the domain.
- The Application Load Balancer (ALB) receives this request. The ALB has been configured with an SSL certificate from AWS Certificate Manager (ACM). The ALB uses this certificate to decrypt the HTTPS request and turns it into a standard HTTP request.
- The ALB then forwards this HTTP request to one of the targets in its target group. In this case, these targets are the tasks running in the ECS service.
- Requests hit the nginx reverse proxy, terminating tls encryption, but we are now in a private subnet which is locked down, nginx proxies request to the django application container on port 8000.

## Features

- The entire AWS infrastructure is provisioned using Terraform, which provides an efficient way to manage infrastructure as code.
- The Django website is containerized using Docker, making it easy to manage dependencies and deployment.
- The application uses AWS Fargate for serverless container execution, removing the need to manage and provision servers.
- The application is highly available and scalable, with auto scaling configured to handle varying loads.
- AWS Cloudwatch is used for monitoring and AWS SNS is used for sending alerts.
- The application is secure with HTTPS enabled, using an SSL certificate provided by AWS Certificate Manager.


## django-blog application
The core of this project is a Django-based blog application.

### Features: implemented
- Post Creation: Users(currently just myself) can create new blog posts with a title and content.
- User Authentication: The application includes a user registration and authentication system. Registered users can create and manage their own blog posts.
- Responsive Design: The blog is designed to be responsive, making it accessible on various devices like desktops, laptops, and mobile phones.

### Features: backlog
- micro-service applications powered by Aritificial Intelligence API's.
- Categories/Tags: Posts can be categorized or tagged for easy navigation and searchability.
- Search: Users can search for blog posts based on keywords or tags.
- Commenting System: Readers can comment on blog posts, facilitating discussions and interactions between the blog post author and readers.
- CICD/Pipeline: github actions
- monitoring: traffic and security
- backup and disaster recovery: RDS review and/or static/media/db cloud backups
- secrets manager: integrate with service for future api access needs


## Design & Frontend

The blog application uses HTML, CSS, and JavaScript for its frontend. The layout is clean and intuitive, making it easy for users to navigate through the blog posts. The use of responsive design principles ensures that the blog is accessible and user-friendly across a range of devices.

### Security

Security is a key focus of this blog application. Django's built-in security features are used extensively, including protection against CSRF, XSS, and SQL Injection attacks. Additionally, the following security measures are also implemented:

- HTTPS: All traffic between the client and the server is encrypted using HTTPS, ensuring the confidentiality and integrity of the data in transit.
- HSTS: HTTP Strict Transport Security (HSTS) is enabled to ensure that browsers only connect to the server using a secure HTTPS connection.
- Secure Cookies: The application's cookies are configured to be sent over HTTPS connections only, protecting them from being intercepted over unsecured connections.
