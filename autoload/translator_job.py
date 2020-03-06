from translator_api import *
import time

while True:
    q = input()
    print(translate_safe(q))
    time.sleep(1)
