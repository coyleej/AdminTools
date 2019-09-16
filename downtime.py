#!/usr/bin/python3
# -*- coding: utf-8 -*-

"""
Monitors internet connection for downtime. Outputs results in a .csv file
Author: waleedahmad
Modified by: Eric Harper (harperes)
Date: 2019-05-29
"""

import os
import csv
import sys
import time
import socket
import datetime


def internet(host="google.com", port=80, timeout=3):
    """ Generates a new request"""
    try:
        socket.setdefaulttimeout(timeout)
        socket.socket(socket.AF_INET, socket.SOCK_STREAM).connect((host, port))
        return True
    except Exception as ex:
        return False


def current_timestamp():
    """ Get Current timestamp string """
    return datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S")


def str_to_date(timestamp):
    """ Convert timestamp string to date object """
    return datetime.datetime.strptime(timestamp, "%Y-%m-%d %H:%M:%S")


def secs_to_HMS(secs):
    """ Convert seconds to second and minutes
    Format : HH:MM:SS
    """
    return str(datetime.timedelta(seconds=secs));


def record_file_exist():
    """ Check if records file exist """
    return os.path.isfile('data.csv')


def create_record_file():
    """ Create a new record file """
    with open('data.csv', 'a') as csvfile:
        columns = ['timestamp', 'status']
        writer = csv.DictWriter(csvfile, fieldnames=columns)
        writer.writeheader()


def last_record_status():
    """ Get last record """
    result = None
    with open('data.csv', 'r') as csvfile:
        reader = csv.DictReader(csvfile)
        for row in reader:
            result = row
    return None if result is None else result['status']


def write_record(status):
    """ Create a new record """
    with open('data.csv', 'a') as csvfile:
        columns = ['timestamp', 'status']
        writer = csv.DictWriter(csvfile, fieldnames=columns)
        writer.writerow({'timestamp': str(current_timestamp()), 'status': status})


def get_total_downtime():
    """ Calculate downtime """
    seconds = 0
    down = None
    up = None
    with open('data.csv', 'r') as csvfile:
        reader = csv.DictReader(csvfile)
        for record in reader:
            try:
                if record['status'] is '0':
                    print('Went Down at : ', record['timestamp'])
                    down = str_to_date(record['timestamp'])
                    next_record = next(reader)
                    up = str_to_date(next_record['timestamp'])
                    seconds += (up - down).total_seconds()
                    print('Went up at   : ', next_record['timestamp'])
            except Exception as ex:
                print('\nCurrent Status    :  Still Down')
                seconds += (str_to_date(current_timestamp()) - down).total_seconds()
    return secs_to_HMS(seconds);


def monitor_connection(sleep_time):
    """ Start monitoring """
    print('Monitoring your connection')
    while True:
        last_record = last_record_status()
        if not internet():
            if last_record is '1' or last_record is None:
                print('Internet went down')
                write_record(0)
        else:
            if last_record is '0' or last_record is None:
                print('Internet is up')
                write_record(1)
        time.sleep(sleep_time)


def args_error():
    print('Please provide an argument\nOptions\n./internet.py monitor\n./internet.py downtime')


args = sys.argv
if not len(args) > 1:
    args_error()
elif args[1] == 'monitor':
    if not record_file_exist():
        create_record_file()
    monitor_connection(1)
elif args[1] == 'downtime':
    print('\nRemained down for : ', get_total_downtime(), ' HH:MM:SS ')
