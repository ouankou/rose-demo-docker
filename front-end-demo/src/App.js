import React from 'react';
import './App.css';
import Entry from "./Dashboard/Dashboard";

class App extends React.Component {
    render() {
        return (
            <div>
                <Entry {...this.props} />
            </div>
        );
    }
}

export default App;
