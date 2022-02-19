#!/usr/bin/python3

DAY_RANGE = 90
NUM_OF_TRANSACTIONS = 10_000_000

import random

class WeightedChoice(object):
    def __init__(self, weights):
        """Pick items with weighted probabilities.
             https://stackoverflow.com/a/1556403/4504053

            weights
                a sequence of tuples of item and it's weight.
        """
        self._total_weight = 0.
        self._item_levels = []
        for item, weight in weights:
            self._total_weight += weight
            self._item_levels.append((self._total_weight, item))
        assert self._total_weight == 1, f"total weighted chance across all item must equal to 1.0"

    def pick(self):
        pick = self._total_weight * random.random()
        for level, item in self._item_levels:
            if level >= pick:
                return item

# Initialize distribution pool

merchantPool = WeightedChoice([
    ("merchant-1", 0.8), 
    ("merchant-2", 0.1), 
    ("merchant-3", 0.05),
    ("merchant-4", 0.04),
    ("merchant-5", 0.001),
    ("merchant-6", 0.001),
    ("merchant-7", 0.001),
    ("merchant-8", 0.001),
    ("merchant-9", 0.001),
    ("merchant-10", 0.001),
    ("merchant-11", 0.001),
    ("merchant-12", 0.001),
    ("merchant-13", 0.001),
    ("merchant-14", 0.001),
])

storePool = WeightedChoice([
    ("store-1", 0.2), 
    ("store-2", 0.2), 
    ("store-3", 0.2), 
    ("store-4", 0.2), 
    ("store-5", 0.2), 
])

category1Pool = WeightedChoice([
    (1, 0.4),
    (2, 0.3),
    (3, 0.3),
])
category2Pool = WeightedChoice([
    (1, 0.5),
    (2, 0.5),
])
category3Pool = WeightedChoice([
    (1, 0.5),
    (2, 0.5),
])
category4Pool = WeightedChoice([
    (1, 0.5),
    (2, 0.5),
])
category5Pool = WeightedChoice([
    (1, 0.5),
    (2, 0.3),
    (3, 0.2),
])

# Generate data

header = [
    'transaction_created_time',
    'transaction_updated_time',
    'timezone_shift',

    'transaction_id',
    'alternative_id_1',
    'alternative_id_2',
    'alternative_id_3',
    'alternative_id_4',
    'alternative_id_5',

    'merchant_id',
    'store_id',
    'category_1',
    'category_2',
    'category_3',
    'category_4',
    'category_5',

    'fee_1',
    'fee_2',
    'fee_3',
    'fee_4',
    'fee_5',
    'fee_6',
    'fee_7',
    'fee_8',
    'fee_9',
    'total_fee'
]

from functools import reduce
import csv
import uuid
import datetime
from faker import Faker
from progressbar import progressbar

with open('transactions.csv', 'w', encoding='UTF8') as f:
    writer = csv.writer(f)
    writer.writerow(header)
    fake = Faker()

    now = datetime.datetime.now()
    start_time = now - datetime.timedelta(days = DAY_RANGE)
    delta_between_transactions = (now - start_time).total_seconds() * 1000 / NUM_OF_TRANSACTIONS
    delta_between_transactions = datetime.timedelta(milliseconds=delta_between_transactions)
    current_time = start_time

    for i in progressbar(range(NUM_OF_TRANSACTIONS)):
        fees = [random.randint(1, 100), random.randint(1, 100), random.randint(1, 100), random.randint(1, 100), random.randint(1, 100), random.randint(1, 100), random.randint(1, 100), random.randint(1, 100), random.randint(1, 100)]
        total_fees = reduce(lambda a,  b: a + b, fees)
        data = [
            current_time,
            current_time,
            25200,

            uuid.uuid1(),
            uuid.uuid1(),
            uuid.uuid1(),
            uuid.uuid1(),
            uuid.uuid1(),
            uuid.uuid1(),

            merchantPool.pick(),
            storePool.pick(),

            category1Pool.pick(),
            category2Pool.pick(),
            category3Pool.pick(),
            category4Pool.pick(),
            category5Pool.pick(),

            fees[0],
            fees[1],
            fees[2],
            fees[3],
            fees[4],
            fees[5],
            fees[6],
            fees[7],
            fees[8],
            total_fees,
        ]
        writer.writerow(data)
        current_time += delta_between_transactions
