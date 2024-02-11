pwm_period = 256
min_width = 0
level_count = 26
gamma = 2.4


def level_value(index: int) -> int:
    if index == 0:
        return 0
    return min_width + round((pwm_period - 1 - min_width) * (index / (level_count - 1))**gamma)


with open('levels.asm', 'w') as file:
    file.write(f'; {level_count} levels, gamma = {gamma}\n')
    
    for i in range(level_count):
        file.write(f'    .dw  {level_value(i)}\n')
