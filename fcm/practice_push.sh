#!/bin/bash
api_key=AAAAM5ee1S0:APA91bHKriOYAzYRuQlHIu2BblX4kX5jlAaKBEa-HAduKwtHODm0b324dDszdDle0axvyn43PgLJoT_TTeUKi5zAIG6VY8raD7wUalzTrnoKQ9HPlN1tHvAU329K4Us2UGboc-ssEq1T
# token=dwCkEKC9RgGkHguxYpVMh2:APA91bGcJ-saF1o64XXei4azEIUuolKMhmbMhfPhzv4_agizGL2hlif4iGhvPh6SuvYptS-fgsEKqyt7XSx3JY1UjgiYC-l2YhouEVWMiayyVONOuo0EkWljLnQjrAs0-mq59-W2eN56
type=data
date="2022/2/15"
weather="sunny day"
#type=notification
curl --header "Authorization: key=$api_key" \
     --header Content-Type:"application/json" \
     https://fcm.googleapis.com/fcm/send \
     -d "{\"to\":\"/topics/all\",\"priority\":\"high\",\"notification\":{\"title\":\"$date\",\"body\":\"$weather\",\"sound\":\"default\"},\"$type\":{\"id\":\"3\",\"title\":\"COFFEE\",\"message\":\"GOOD TASTE\",\"type\":\"notification\"}}"