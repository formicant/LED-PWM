from math import ceil


pwm_period = 512
level_count = 24
gamma = 2.5


def level_value(index: int) -> int:
    return ceil((pwm_period - 1) * (index / (level_count - 1))**gamma)


with open('levels.asm', 'w') as file:
    file.write(f'; {level_count} levels, gamma = {gamma}\n')
    
    for i in range(level_count):
        file.write(f'    .dw  {level_value(i)}\n')
