pwm_period = 256
level_count = 22
gamma = 2.5


def level_value(index: int) -> int:
    if index == 0:
        return 0
    return 1 + round((pwm_period - 2) * (index / (level_count - 1))**gamma)


with open('levels.asm', 'w') as file:
    file.write(f'; {level_count} levels, gamma = {gamma}\n')
    
    for i in range(level_count):
        file.write(f'    .dw  {level_value(i)}\n')
