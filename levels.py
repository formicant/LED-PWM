from dataclasses import dataclass
from typing import TextIO


@dataclass
class Parameters:
    pwm_period: int
    min_width: int
    level_count: int
    gamma: float


profiles = {
    'lena': Parameters(
        pwm_period  = 256,
        min_width   =   1,
        level_count =  23,
        gamma       = 2.5
    ),
    'saxa': Parameters(
        pwm_period  = 256,
        min_width   =   0,
        level_count =  26,
        gamma       = 2.4
    ),
}


def level_value(p: Parameters, index: int) -> int:
    if index == 0:
        return 0
    return p.min_width + round((p.pwm_period - 1 - p.min_width) * (index / (p.level_count - 1))**p.gamma)


def write_levels(name: str, p: Parameters) -> None:
    with open(f'levels-{name}.asm', 'w') as file:
        file.write(f'; {name}\n')
        file.write(f'; {p.level_count} levels, gamma = {p.gamma}\n')
        for i in range(p.level_count):
            file.write(f'    .dw  {level_value(p, i)}\n')


if __name__ == '__main__':
    for name, parameters in profiles.items():
        write_levels(name, parameters)
