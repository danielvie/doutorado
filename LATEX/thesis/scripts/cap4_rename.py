from glob import glob
from os import rename

if __name__ == "__main__":
    

    F = glob("Cap3/cap3_linearizacao*")
    
    for f in F:
        
        name = f.replace('_linearizacao_', '_linearization_')
        
        rename(f, name)

