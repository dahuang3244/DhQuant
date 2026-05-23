from server.shared.time.clock import now
from server.shared.time.calendar import is_trading_day, next_trading_day

print(now())                    # 带时区的当前时间
print(is_trading_day())         # 今天是否交易日
print(next_trading_day())       # 下一个交易日