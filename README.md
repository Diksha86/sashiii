Assign the user compute.osLogin role and iam.serviceAccountUser role, so that the user is able to ssh into the instance and restart the service using command                                                                                                                                                         
    sudo /etc/init.d/nginx restart
For the target instance set custom metadata tag to key: enable-oslogin, value: true
Make changes in the visudo file so that the user can only access the web server for restarting.
   username ALL =NOPASSWD: /etc/init.d/nginx
