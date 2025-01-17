import matplotlib.pyplot as plt
import pandas as pd
import numpy as np

def fit_ls(data):
    # computing least square
    x = data[:,0]
    y = data[:,1]
    
    X = np.vstack([np.ones_like(x), x]).T
    
    beta = np.linalg.inv(X.T @ X) @ X.T @ y
    return beta

def get_data_lab():
    an4 = np.array([
        [573, 412],
        [1017, 860],
        [1443, 1281],
        [2054, 1887],
        [2543, 2384],
        [2958, 3003],
    ])

    an5 = np.array( [
        [554, 394],
        [1055, 899],
        [1413, 1256],
        [2029, 1865],
        [2577, 2428],
        [2973, 3030],
    ])

    an6 = np.array( [
        [465, 309],
        [1000, 853],
        [1444, 1289],
        [1986, 1816],
        [2503, 2343],
        [3101, 3271] 
    ])
    
    return {
        'a4': an4,
        'a5': an5,
        'a6': an6,
    }


def get_data_home():
    an6 = np.array([
        [0.500, 0.343],
        [1.000, 0.842],
        [1.500, 1.342],
        [2.000, 1.828],
        [2.500, 2.341],
        [3.000, 3.080],
    ])

    an5 = np.array([
        [0.500, 0.346],
        [1.000, 0.844],
        [1.500, 1.343],
        [2.000, 1.834],
        [2.500, 2.343],
        [3.000, 3.080],
    ])

    an4 = np.array([
        [0.500, 0.347],
        [1.000, 0.841],
        [1.500, 1.340],
        [2.000, 1.834],
        [2.500, 2.344],
        [3.000, 3.076],
    ])

    return {
        'a4': an4,
        'a5': an5,
        'a6': an6,
    }

def main():
    data = get_data_home()
    
    a4 = data.get('a4')
    a5 = data.get('a5')
    a6 = data.get('a6')
    
    # remove last point
    a4 = a4[:-1, :]
    a5 = a5[:-1, :]
    a6 = a6[:-1, :]

    # combine data
    x = np.hstack([a4[:,0], a5[:,0], a6[:,0]])
    y = np.hstack([a4[:,1], a5[:,1], a6[:,1]])

    # fit data
    X = np.vstack([np.ones_like(x), x]).T
    beta = np.linalg.inv(X.T @ X) @ X.T @ y
    print(beta)
    
    # xx = np.linspace(x.min(), x.max(), 10)
    # yy = xx * beta[1] + beta[0]
    
    # table of results
    def transf(x):
        return (x*beta[1] + beta[0])
        
    def esp2multi(x):
        return (x-beta[0])/beta[1]
        
    def show_data(data):
        x = data[:,0]
        y = data[:,1]
        
        est = esp2multi(y)
        error = est - x

        d = {
            'multimeter': x,
            'esp': y,
            'estimative': est,
            'error': error,
        }
        print(pd.DataFrame(d))


    print('\nd4')
    show_data(a4)

    print('\nd5')
    show_data(a5)

    print('\nd6')
    show_data(a6)
    

    
    # plt.plot(a4[:,0], a4[:, 1], '*-')
    # plt.plot(a5[:,0], a5[:, 1], '*-')
    # plt.plot(a6[:,0], a6[:, 1], '*-')
    # plt.plot(xx, yy, '--k', linewidth=2)
    # plt.axis('equal')
    # plt.xlabel('multimeter [mV]')
    # plt.ylabel('esp [mV]')
    # plt.grid(True)
    # plt.show()

if __name__ == "__main__":
    main()
