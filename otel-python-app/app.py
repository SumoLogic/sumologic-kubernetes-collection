import logging
import time

print("Starting auto-instrumented Python app", flush=True)

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger("otel-python-emitter")

counter = 0
while True:
    counter += 1
    print(f"[stdout] iteration {counter}", flush=True)
    logger.info(f"Emitting log record {counter} from auto-instrumented Python app")
    logger.warning(f"Sample warning log {counter}")
    time.sleep(10)
